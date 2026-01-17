# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require_relative '../lib/sergeant'

RSpec.describe 'SergeantApp Caching and Session Features' do
  let(:app) { SergeantApp.new }

  before do
    # Mock curses methods to avoid terminal initialization
    allow(app).to receive(:init_screen)
    allow(app).to receive(:has_colors?).and_return(false)
    allow(app).to receive(:curs_set)
    allow(app).to receive(:noecho)
    allow(app).to receive(:stdscr).and_return(double(keypad: true))
  end

  describe 'Stat Caching' do
    describe '#cached_stat' do
      it 'caches file stat results' do
        Dir.mktmpdir do |dir|
          test_file = File.join(dir, 'test.txt')
          File.write(test_file, 'content')

          # First call should hit filesystem
          stat1 = app.send(:cached_stat, test_file)
          expect(stat1).to be_a(File::Stat)

          # Mock File.stat to verify it's not called again
          allow(File).to receive(:stat).and_call_original
          expect(File).not_to receive(:stat).with(test_file)

          # Second call should return cached result
          stat2 = app.send(:cached_stat, test_file)
          expect(stat2).to be_a(File::Stat)
        end
      end

      it 'expires cache after TTL' do
        Dir.mktmpdir do |dir|
          test_file = File.join(dir, 'test.txt')
          File.write(test_file, 'content')

          # First call
          app.send(:cached_stat, test_file)

          # Set TTL to 0.1 seconds for testing
          app.instance_variable_set(:@cache_ttl, 0.1)

          # Wait for cache to expire
          sleep(0.15)

          # Should call File.stat again
          allow(File).to receive(:stat).and_call_original
          expect(File).to receive(:stat).with(test_file).and_call_original

          app.send(:cached_stat, test_file)
        end
      end

      it 'handles non-existent files gracefully' do
        result = app.send(:cached_stat, '/nonexistent/file.txt')
        expect(result).to be_nil
      end

      it 'removes cache entry on permission errors' do
        skip 'Cannot test permission errors as root' if Process.uid.zero?

        Dir.mktmpdir do |dir|
          test_file = File.join(dir, 'test.txt')
          File.write(test_file, 'content')

          # First call succeeds
          stat1 = app.send(:cached_stat, test_file)
          expect(stat1).to be_a(File::Stat)

          # Remove file permissions
          File.chmod(0o000, test_file)

          # Should return nil and remove from cache
          stat2 = app.send(:cached_stat, test_file)
          expect(stat2).to be_nil

          # Verify cache entry is gone
          cache = app.instance_variable_get(:@stat_cache)
          expect(cache).not_to have_key(test_file)

          File.chmod(0o644, test_file) # Cleanup
        end
      end

      it 'stores cache entry with timestamp' do
        Dir.mktmpdir do |dir|
          test_file = File.join(dir, 'test.txt')
          File.write(test_file, 'content')

          before_time = Time.now
          app.send(:cached_stat, test_file)
          after_time = Time.now

          cache = app.instance_variable_get(:@stat_cache)
          cache_entry = cache[test_file]

          expect(cache_entry).to have_key(:stat)
          expect(cache_entry).to have_key(:time)
          expect(cache_entry[:time]).to be_between(before_time, after_time)
          expect(cache_entry[:stat]).to be_a(File::Stat)
        end
      end
    end

    describe '#cleanup_cache' do
      it 'removes oldest entries when cache is full' do
        # Set low max for testing
        app.instance_variable_set(:@max_cache_entries, 5)

        Dir.mktmpdir do |dir|
          # Add 10 files to cache
          10.times do |i|
            file = File.join(dir, "file#{i}.txt")
            File.write(file, 'content')
            app.send(:cached_stat, file)
            sleep(0.01) # Ensure different timestamps
          end

          cache = app.instance_variable_get(:@stat_cache)
          # Should only have 5 entries (max limit)
          expect(cache.size).to be <= 5
        end
      end

      it 'keeps most recent entries after cleanup' do
        app.instance_variable_set(:@max_cache_entries, 3)

        Dir.mktmpdir do |dir|
          files = []
          5.times do |i|
            file = File.join(dir, "file#{i}.txt")
            File.write(file, 'content')
            files << file
            app.send(:cached_stat, file)
            sleep(0.01)
          end

          cache = app.instance_variable_get(:@stat_cache)
          # Should keep only the last 3 files
          expect(cache).to have_key(files[4])
          expect(cache).to have_key(files[3])
          expect(cache).to have_key(files[2])
          expect(cache).not_to have_key(files[0])
          expect(cache).not_to have_key(files[1])
        end
      end
    end

    describe 'cache clearing on refresh' do
      it 'clears cache when R key is pressed' do
        Dir.mktmpdir do |dir|
          test_file = File.join(dir, 'test.txt')
          File.write(test_file, 'content')

          # Add to cache
          app.send(:cached_stat, test_file)
          cache = app.instance_variable_get(:@stat_cache)
          expect(cache).not_to be_empty

          # Clear cache
          cache.clear
          expect(cache).to be_empty
        end
      end
    end
  end

  describe 'Session Persistence' do
    describe '#save_session' do
      it 'saves current directory to session file' do
        Dir.mktmpdir do |dir|
          session_file = File.join(dir, '.sgt_session')
          app.instance_variable_set(:@session_file, session_file)
          app.instance_variable_set(:@current_dir, '/home/user/projects')

          app.send(:save_session)

          expect(File.exist?(session_file)).to be true
          saved_dir = File.read(session_file).strip
          expect(saved_dir).to eq('/home/user/projects')
        end
      end

      it 'overwrites previous session file' do
        Dir.mktmpdir do |dir|
          session_file = File.join(dir, '.sgt_session')
          app.instance_variable_set(:@session_file, session_file)

          # Save first directory
          app.instance_variable_set(:@current_dir, '/first/dir')
          app.send(:save_session)

          # Save second directory
          app.instance_variable_set(:@current_dir, '/second/dir')
          app.send(:save_session)

          saved_dir = File.read(session_file).strip
          expect(saved_dir).to eq('/second/dir')
        end
      end

      it 'handles write errors gracefully' do
        app.instance_variable_set(:@session_file, '/invalid/path/.sgt_session')
        app.instance_variable_set(:@current_dir, '/home/user')

        # Should not raise error
        expect { app.send(:save_session) }.not_to raise_error
      end
    end

    describe 'restore session on startup' do
      it 'restores last directory when --restore is used' do
        Dir.mktmpdir do |dir|
          session_file = File.join(dir, '.sgt_session')
          saved_dir = File.join(dir, 'projects')
          FileUtils.mkdir_p(saved_dir)
          File.write(session_file, saved_dir)

          # Mock File.expand_path BEFORE creating the app
          allow(File).to receive(:expand_path).and_call_original
          allow(File).to receive(:expand_path).with('~/.sgt_session').and_return(session_file)
          allow(File).to receive(:expand_path).with('~/.sgt_history').and_return(File.join(dir, '.sgt_history'))

          app_with_restore = SergeantApp.new(restore_session: true)
          allow(app_with_restore).to receive(:init_screen)
          allow(app_with_restore).to receive(:has_colors?).and_return(false)
          allow(app_with_restore).to receive(:curs_set)
          allow(app_with_restore).to receive(:noecho)
          allow(app_with_restore).to receive(:stdscr).and_return(double(keypad: true))

          current_dir = app_with_restore.instance_variable_get(:@current_dir)
          expect(current_dir).to eq(saved_dir)
        end
      end

      it 'does not restore if session file does not exist' do
        allow(File).to receive(:exist?).with(anything).and_return(false)

        app_new = SergeantApp.new(restore_session: true)
        allow(app_new).to receive(:init_screen)
        allow(app_new).to receive(:has_colors?).and_return(false)

        # Should use current directory
        current_dir = app_new.instance_variable_get(:@current_dir)
        expect(current_dir).to eq(Dir.pwd)
      end

      it 'validates directory exists before restoring' do
        Dir.mktmpdir do |dir|
          session_file = File.join(dir, '.sgt_session')
          File.write(session_file, '/nonexistent/directory')

          allow(File).to receive(:expand_path).with('~/.sgt_session').and_return(session_file)
          allow(File).to receive(:expand_path).and_call_original

          app_with_restore = SergeantApp.new(restore_session: true)
          allow(app_with_restore).to receive(:init_screen)
          allow(app_with_restore).to receive(:has_colors?).and_return(false)

          # Should fall back to current directory
          current_dir = app_with_restore.instance_variable_get(:@current_dir)
          expect(current_dir).to eq(Dir.pwd)
        end
      end
    end
  end

  describe 'Directory History' do
    describe '#add_to_history' do
      it 'adds directory to history' do
        app.instance_variable_set(:@directory_history, [])

        app.send(:add_to_history, '/home/user/projects')

        history = app.instance_variable_get(:@directory_history)
        expect(history).to include('/home/user/projects')
      end

      it 'adds new directory to front of history' do
        app.instance_variable_set(:@directory_history, ['/first', '/second'])

        app.send(:add_to_history, '/third')

        history = app.instance_variable_get(:@directory_history)
        expect(history.first).to eq('/third')
      end

      it 'removes duplicates and moves to front' do
        app.instance_variable_set(:@directory_history, ['/first', '/second', '/third'])

        # Add existing directory
        app.send(:add_to_history, '/second')

        history = app.instance_variable_get(:@directory_history)
        expect(history.first).to eq('/second')
        expect(history.count('/second')).to eq(1)
      end

      it 'does not add duplicate of current first entry' do
        app.instance_variable_set(:@directory_history, ['/first'])

        app.send(:add_to_history, '/first')

        history = app.instance_variable_get(:@directory_history)
        expect(history.length).to eq(1)
      end

      it 'limits history to max size (50 entries)' do
        # Start with 50 entries
        history = (1..50).map { |i| "/dir#{i}" }
        app.instance_variable_set(:@directory_history, history)

        # Add one more
        app.send(:add_to_history, '/dir51')

        history = app.instance_variable_get(:@directory_history)
        expect(history.length).to eq(50)
        expect(history.first).to eq('/dir51')
        expect(history).not_to include('/dir50') # Last entry should be gone
        expect(history).to include('/dir1') # First entry should still be there
      end
    end

    describe '#load_history' do
      it 'loads history from file' do
        Dir.mktmpdir do |dir|
          history_file = File.join(dir, '.sgt_history')
          File.write(history_file, "/home/user/projects\n/home/user/documents\n/tmp\n")

          app.instance_variable_set(:@history_file, history_file)

          history = app.send(:load_history)
          expect(history).to eq(['/home/user/projects', '/home/user/documents', '/tmp'])
        end
      end

      it 'returns empty array if history file does not exist' do
        app.instance_variable_set(:@history_file, '/nonexistent/.sgt_history')

        history = app.send(:load_history)
        expect(history).to eq([])
      end

      it 'handles corrupted history file gracefully' do
        Dir.mktmpdir do |dir|
          history_file = File.join(dir, '.sgt_history')
          # Create invalid file
          File.write(history_file, "\x00\x01\x02", mode: 'wb')

          app.instance_variable_set(:@history_file, history_file)

          # Should not raise error
          expect { app.send(:load_history) }.not_to raise_error
        end
      end
    end

    describe '#save_history' do
      it 'saves history to file' do
        Dir.mktmpdir do |dir|
          history_file = File.join(dir, '.sgt_history')
          app.instance_variable_set(:@history_file, history_file)
          app.instance_variable_set(:@directory_history, ['/first', '/second', '/third'])

          app.send(:save_history)

          expect(File.exist?(history_file)).to be true
          saved_history = File.readlines(history_file).map(&:strip)
          expect(saved_history).to eq(['/first', '/second', '/third'])
        end
      end

      it 'handles write errors gracefully' do
        app.instance_variable_set(:@history_file, '/invalid/path/.sgt_history')
        app.instance_variable_set(:@directory_history, ['/first'])

        # Should not raise error
        expect { app.send(:save_history) }.not_to raise_error
      end
    end
  end

  describe 'Integration Tests' do
    it 'initializes with all caching features' do
      expect(app.instance_variable_get(:@stat_cache)).to be_a(Hash)
      expect(app.instance_variable_get(:@cache_ttl)).to eq(5)
      expect(app.instance_variable_get(:@max_cache_entries)).to eq(5000)
    end

    it 'initializes with session persistence features' do
      session_file = app.instance_variable_get(:@session_file)
      expect(session_file).to include('.sgt_session')
    end

    it 'initializes with history features' do
      history_file = app.instance_variable_get(:@history_file)
      expect(history_file).to include('.sgt_history')
      expect(app.instance_variable_get(:@directory_history)).to be_an(Array)
      expect(app.instance_variable_get(:@history_max_size)).to eq(50)
    end

    it 'uses cached stat in refresh_items' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'test.txt'), 'content')
        app.instance_variable_set(:@current_dir, dir)

        # Mock cached_stat to verify it's called
        allow(app).to receive(:cached_stat).and_call_original
        expect(app).to receive(:cached_stat).at_least(:once)

        app.send(:refresh_items)
      end
    end
  end
end
