# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require_relative '../lib/sergeant'

RSpec.describe 'SergeantApp Performance Optimizations' do
  let(:app) { SergeantApp.new }

  before do
    # Mock curses methods to avoid terminal initialization
    allow(app).to receive(:init_screen)
    allow(app).to receive(:has_colors?).and_return(false)
    allow(app).to receive(:curs_set)
    allow(app).to receive(:noecho)
    allow(app).to receive(:stdscr).and_return(double(keypad: true))
  end

  describe '#refresh_items_if_needed' do
    it 'refreshes items when directory changes' do
      Dir.mktmpdir do |dir|
        app.instance_variable_set(:@current_dir, dir)

        expect(app).to receive(:refresh_items).once
        app.send(:refresh_items_if_needed)
      end
    end

    it 'does not refresh when directory stays the same' do
      Dir.mktmpdir do |dir|
        app.instance_variable_set(:@current_dir, dir)
        app.send(:refresh_items_if_needed)  # First call

        expect(app).not_to receive(:refresh_items)
        app.send(:refresh_items_if_needed)  # Second call - should not refresh
      end
    end

    it 'refreshes when ownership toggle changes' do
      Dir.mktmpdir do |dir|
        app.instance_variable_set(:@current_dir, dir)
        app.send(:refresh_items_if_needed)  # Initial refresh

        # Change ownership toggle
        app.instance_variable_set(:@show_ownership, true)

        expect(app).to receive(:refresh_items).once
        app.send(:refresh_items_if_needed)  # Should refresh
      end
    end
  end

  describe '#force_refresh' do
    it 'resets cache to force next refresh' do
      Dir.mktmpdir do |dir|
        app.instance_variable_set(:@current_dir, dir)
        app.send(:refresh_items_if_needed)  # Cache the directory

        # Force refresh
        app.send(:force_refresh)

        expect(app).to receive(:refresh_items).once
        app.send(:refresh_items_if_needed)  # Should refresh due to force
      end
    end
  end

  describe '#refresh_items performance' do
    it 'only fetches owner info when show_ownership is true' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'test.txt'), 'content')
        app.instance_variable_set(:@current_dir, dir)
        app.instance_variable_set(:@show_ownership, false)

        # Mock get_owner_info to track calls
        allow(app).to receive(:get_owner_info).and_call_original

        app.send(:refresh_items)

        # Should not call get_owner_info when ownership is off
        expect(app).not_to have_received(:get_owner_info)
      end
    end

    it 'fetches owner info when show_ownership is true' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'test.txt'), 'content')
        app.instance_variable_set(:@current_dir, dir)
        app.instance_variable_set(:@show_ownership, true)

        allow(app).to receive(:get_owner_info).and_call_original

        app.send(:refresh_items)

        # Should call get_owner_info when ownership is on
        expect(app).to have_received(:get_owner_info).at_least(:once)
      end
    end

    it 'uses stat.directory? instead of File.directory?' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'test.txt'), 'content')
        app.instance_variable_set(:@current_dir, dir)

        # Should not call File.directory? (uses stat.directory? instead)
        expect(File).not_to receive(:directory?)

        app.send(:refresh_items)
      end
    end
  end

  describe 'directory listing' do
    it 'sorts directories before files' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'a_file.txt'), 'content')
        FileUtils.mkdir_p(File.join(dir, 'z_directory'))
        File.write(File.join(dir, 'b_file.txt'), 'content')
        FileUtils.mkdir_p(File.join(dir, 'a_directory'))

        app.instance_variable_set(:@current_dir, dir)
        app.send(:refresh_items)

        items = app.instance_variable_get(:@items)
        # Skip '..' entry if present
        items = items.reject { |i| i[:name] == '..' }

        # First items should be directories
        expect(items[0][:type]).to eq(:directory)
        expect(items[1][:type]).to eq(:directory)
        expect(items[2][:type]).to eq(:file)
        expect(items[3][:type]).to eq(:file)
      end
    end

    it 'sorts items alphabetically within type' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'zebra.txt'), 'content')
        File.write(File.join(dir, 'alpha.txt'), 'content')
        File.write(File.join(dir, 'beta.txt'), 'content')

        app.instance_variable_set(:@current_dir, dir)
        app.send(:refresh_items)

        items = app.instance_variable_get(:@items)
        file_items = items.select { |i| i[:type] == :file }

        expect(file_items[0][:name]).to eq('alpha.txt')
        expect(file_items[1][:name]).to eq('beta.txt')
        expect(file_items[2][:name]).to eq('zebra.txt')
      end
    end

    it 'handles empty directories' do
      Dir.mktmpdir do |dir|
        app.instance_variable_set(:@current_dir, dir)

        expect { app.send(:refresh_items) }.not_to raise_error

        items = app.instance_variable_get(:@items)
        # Should only have '..' entry
        expect(items.length).to be <= 1
      end
    end

    it 'handles permission errors gracefully' do
      skip 'Cannot test permission errors as root' if Process.uid.zero?

      Dir.mktmpdir do |dir|
        restricted_dir = File.join(dir, 'restricted')
        FileUtils.mkdir_p(restricted_dir)
        File.write(File.join(restricted_dir, 'file.txt'), 'content')
        File.chmod(0o000, restricted_dir)

        app.instance_variable_set(:@current_dir, dir)

        expect { app.send(:refresh_items) }.not_to raise_error

        File.chmod(0o755, restricted_dir) # Cleanup
      end
    end
  end
end
