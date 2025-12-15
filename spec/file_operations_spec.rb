# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

# Load the module first
require_relative '../lib/modals/file_operations'

# Create a test class that includes the FileOperations module
# We need to mock the curses-related methods
class FileOperationsTestClass
  include Sergeant::Modals::FileOperations

  attr_accessor :marked_items, :copied_items, :cut_mode, :items, :selected_index

  def initialize
    @marked_items = []
    @copied_items = []
    @cut_mode = false
    @items = []
    @selected_index = 0
  end

  # Mock curses methods
  def show_error_modal(_message); end
  def show_info_modal(_message); end

  def ask_conflict_resolution(_filename)
    :skip
  end
end

RSpec.describe Sergeant::Modals::FileOperations do
  let(:test_obj) { FileOperationsTestClass.new }

  describe '#get_unique_filename' do
    it 'returns original path with _1 suffix when file exists' do
      Dir.mktmpdir do |dir|
        original = File.join(dir, 'test.txt')
        File.write(original, 'content')

        result = test_obj.get_unique_filename(original)
        expect(result).to eq(File.join(dir, 'test_1.txt'))
      end
    end

    it 'increments counter until finding unique name' do
      Dir.mktmpdir do |dir|
        original = File.join(dir, 'test.txt')
        File.write(original, 'content')
        File.write(File.join(dir, 'test_1.txt'), 'content')
        File.write(File.join(dir, 'test_2.txt'), 'content')

        result = test_obj.get_unique_filename(original)
        expect(result).to eq(File.join(dir, 'test_3.txt'))
      end
    end

    it 'handles files without extensions' do
      Dir.mktmpdir do |dir|
        original = File.join(dir, 'README')
        File.write(original, 'content')

        result = test_obj.get_unique_filename(original)
        expect(result).to eq(File.join(dir, 'README_1'))
      end
    end

    it 'preserves directory path' do
      Dir.mktmpdir do |dir|
        subdir = File.join(dir, 'subdir')
        FileUtils.mkdir_p(subdir)
        original = File.join(subdir, 'test.txt')
        File.write(original, 'content')

        result = test_obj.get_unique_filename(original)
        expect(result).to start_with(subdir)
        expect(result).to eq(File.join(subdir, 'test_1.txt'))
      end
    end
  end

  describe 'paste operation logic' do
    it 'clears marked items after paste' do
      Dir.mktmpdir do |dir|
        source_file = File.join(dir, 'source.txt')
        File.write(source_file, 'content')

        test_obj.marked_items = [source_file]
        test_obj.copied_items = [source_file]

        # Call paste_with_modal which should clear items
        allow(test_obj).to receive(:show_info_modal)
        test_obj.paste_with_modal

        expect(test_obj.marked_items).to be_empty
        expect(test_obj.copied_items).to be_empty
      end
    end

    it 'sets cut_mode to false after cut operation' do
      Dir.mktmpdir do |dir|
        source_file = File.join(dir, 'source.txt')
        File.write(source_file, 'content')

        test_obj.cut_mode = true
        test_obj.copied_items = [source_file]

        allow(test_obj).to receive(:show_info_modal)
        test_obj.paste_with_modal

        expect(test_obj.cut_mode).to be false
      end
    end
  end

  describe 'delete operation logic' do
    it 'removes files successfully' do
      Dir.mktmpdir do |dir|
        file1 = File.join(dir, 'file1.txt')
        file2 = File.join(dir, 'file2.txt')
        File.write(file1, 'content1')
        File.write(file2, 'content2')

        test_obj.marked_items = [file1, file2]

        allow(test_obj).to receive(:show_info_modal) do |msg|
          expect(msg).to include('Successfully deleted 2')
        end

        test_obj.delete_with_modal

        expect(File.exist?(file1)).to be false
        expect(File.exist?(file2)).to be false
        expect(test_obj.marked_items).to be_empty
      end
    end

    it 'handles errors gracefully' do
      test_obj.marked_items = ['/nonexistent/file.txt']

      allow(test_obj).to receive(:show_info_modal) do |msg|
        expect(msg).to include('Successfully deleted 0')
      end

      expect { test_obj.delete_with_modal }.not_to raise_error
    end

    it 'removes directories recursively' do
      Dir.mktmpdir do |dir|
        subdir = File.join(dir, 'subdir')
        FileUtils.mkdir_p(subdir)
        File.write(File.join(subdir, 'file.txt'), 'content')

        test_obj.marked_items = [subdir]

        allow(test_obj).to receive(:show_info_modal)
        test_obj.delete_with_modal

        expect(File.exist?(subdir)).to be false
      end
    end
  end

  describe 'paste with different modes' do
    it 'copies files in copy mode' do
      Dir.mktmpdir do |dir|
        source = File.join(dir, 'source.txt')
        dest_dir = File.join(dir, 'dest')
        FileUtils.mkdir_p(dest_dir)
        File.write(source, 'original content')

        test_obj.copied_items = [source]
        test_obj.cut_mode = false
        test_obj.instance_variable_set(:@current_dir, dest_dir)

        allow(test_obj).to receive(:show_info_modal)
        test_obj.paste_with_modal

        # Original should still exist
        expect(File.exist?(source)).to be true
        # Copy should exist
        expect(File.exist?(File.join(dest_dir, 'source.txt'))).to be true
      end
    end

    it 'moves files in cut mode' do
      Dir.mktmpdir do |dir|
        source = File.join(dir, 'source.txt')
        dest_dir = File.join(dir, 'dest')
        FileUtils.mkdir_p(dest_dir)
        File.write(source, 'original content')

        test_obj.copied_items = [source]
        test_obj.cut_mode = true
        test_obj.instance_variable_set(:@current_dir, dest_dir)

        allow(test_obj).to receive(:show_info_modal)
        test_obj.paste_with_modal

        # Original should be gone
        expect(File.exist?(source)).to be false
        # File should exist in new location
        expect(File.exist?(File.join(dest_dir, 'source.txt'))).to be true
      end
    end

    it 'copies directories recursively' do
      Dir.mktmpdir do |dir|
        source_dir = File.join(dir, 'source_dir')
        FileUtils.mkdir_p(source_dir)
        File.write(File.join(source_dir, 'file1.txt'), 'content1')
        File.write(File.join(source_dir, 'file2.txt'), 'content2')

        dest_dir = File.join(dir, 'dest')
        FileUtils.mkdir_p(dest_dir)

        test_obj.copied_items = [source_dir]
        test_obj.cut_mode = false
        test_obj.instance_variable_set(:@current_dir, dest_dir)

        allow(test_obj).to receive(:show_info_modal)
        test_obj.paste_with_modal

        copied_dir = File.join(dest_dir, 'source_dir')
        expect(File.exist?(copied_dir)).to be true
        expect(File.exist?(File.join(copied_dir, 'file1.txt'))).to be true
        expect(File.exist?(File.join(copied_dir, 'file2.txt'))).to be true
      end
    end
  end
end
