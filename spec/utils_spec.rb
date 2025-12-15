# frozen_string_literal: true

require_relative '../lib/utils'

RSpec.describe Sergeant::Utils do
  let(:test_class) { Class.new { include Sergeant::Utils } }
  let(:utils) { test_class.new }

  describe '#format_permissions' do
    it 'formats directory permissions correctly' do
      # drwxr-xr-x = 0755 = 0o040755 (with directory bit)
      mode = 0o040755
      result = utils.format_permissions(mode, true)
      expect(result).to eq('drwxr-xr-x')
    end

    it 'formats file permissions correctly' do
      # -rw-r--r-- = 0644
      mode = 0o100644
      result = utils.format_permissions(mode, false)
      expect(result).to eq('-rw-r--r--')
    end

    it 'formats executable file permissions correctly' do
      # -rwxr-xr-x = 0755
      mode = 0o100755
      result = utils.format_permissions(mode, false)
      expect(result).to eq('-rwxr-xr-x')
    end

    it 'formats no permissions correctly' do
      mode = 0o100000
      result = utils.format_permissions(mode, false)
      expect(result).to eq('----------')
    end

    it 'formats full permissions correctly' do
      mode = 0o100777
      result = utils.format_permissions(mode, false)
      expect(result).to eq('-rwxrwxrwx')
    end
  end

  describe '#format_size' do
    it 'formats bytes correctly' do
      expect(utils.format_size(0)).to eq('     0B')
      expect(utils.format_size(500)).to eq('   500B')
      expect(utils.format_size(1023)).to eq('  1023B')
    end

    it 'formats kilobytes correctly' do
      expect(utils.format_size(1024)).to eq('   1.0K')
      expect(utils.format_size(1536)).to eq('   1.5K')
      expect(utils.format_size(10_240)).to eq('  10.0K')
    end

    it 'formats megabytes correctly' do
      expect(utils.format_size(1_048_576)).to eq('   1.0M')
      expect(utils.format_size(5_242_880)).to eq('   5.0M')
    end

    it 'formats gigabytes correctly' do
      expect(utils.format_size(1_073_741_824)).to eq('   1.0G')
      expect(utils.format_size(2_147_483_648)).to eq('   2.0G')
    end

    it 'pads size strings to 7 characters' do
      expect(utils.format_size(1024).length).to eq(7)
      expect(utils.format_size(1_048_576).length).to eq(7)
    end

    it 'handles nil size' do
      expect(utils.format_size(nil)).to eq('     ')
    end
  end

  describe '#format_date' do
    it 'formats dates with time in MMM DD HH:MM format' do
      time = Time.new(2024, 6, 15, 14, 30, 0)
      result = utils.format_date(time)
      expect(result).to match(/\w{3}\s+\d{1,2}\s+\d{2}:\d{2}/)
      expect(result).to eq('Jun 15 14:30')
    end

    it 'formats recent dates correctly' do
      recent_time = Time.now - (60 * 60) # 1 hour ago
      result = utils.format_date(recent_time)
      expect(result).to match(/\w{3}\s+\d{1,2}\s+\d{2}:\d{2}/)
    end

    it 'handles nil date by returning empty string' do
      expect(utils.format_date(nil)).to eq('')
    end
  end

  describe '#text_file?' do
    it 'returns false for non-existent files' do
      expect(utils.text_file?('/nonexistent/file.txt')).to be false
    end

    it 'returns false for directories' do
      Dir.mktmpdir do |dir|
        expect(utils.text_file?(dir)).to be false
      end
    end

    it 'returns true for text files' do
      Dir.mktmpdir do |dir|
        text_file = File.join(dir, 'test.txt')
        File.write(text_file, "Hello, World!\nThis is a test file.")
        expect(utils.text_file?(text_file)).to be true
      end
    end

    it 'returns false for binary files' do
      Dir.mktmpdir do |dir|
        binary_file = File.join(dir, 'test.bin')
        File.write(binary_file, "\x00\x01\x02\x03\xFF\xFE", mode: 'wb')
        expect(utils.text_file?(binary_file)).to be false
      end
    end

    it 'returns false for files larger than 50MB' do
      Dir.mktmpdir do |dir|
        large_file = File.join(dir, 'large.txt')
        # Create a file that appears to be 51MB (we'll mock the size check)
        File.write(large_file, 'test')
        allow(File).to receive(:size).with(large_file).and_return(51 * 1024 * 1024)
        expect(utils.text_file?(large_file)).to be false
      end
    end

    it 'returns false for unreadable files' do
      Dir.mktmpdir do |dir|
        unreadable_file = File.join(dir, 'unreadable.txt')
        File.write(unreadable_file, 'test')
        File.chmod(0o000, unreadable_file)

        # Skip this test if running as root (root can read files even with 000 permissions)
        skip 'Cannot test unreadable files as root' if Process.uid.zero?

        expect(utils.text_file?(unreadable_file)).to be false
        File.chmod(0o644, unreadable_file) # Cleanup
      end
    end
  end

  describe '#get_owner_info' do
    it 'returns owner username for valid uid' do
      stat = double('stat', uid: Process.uid, gid: Process.gid)
      result = utils.get_owner_info(stat)
      expect(result).to be_a(String)
      expect(result).not_to be_empty
    end

    it 'returns uid as string for unknown user' do
      stat = double('stat', uid: 99999, gid: 99999)
      result = utils.get_owner_info(stat)
      expect(result).to eq('99999:99999')
    end
  end

  describe 'tool availability checks' do
    describe '#fzf_available?' do
      it 'returns true when fzf is available' do
        allow(utils).to receive(:system).with('command -v fzf > /dev/null 2>&1').and_return(true)
        expect(utils.fzf_available?).to be true
      end

      it 'returns false when fzf is not available' do
        allow(utils).to receive(:system).with('command -v fzf > /dev/null 2>&1').and_return(false)
        expect(utils.fzf_available?).to be false
      end
    end

    describe '#glow_available?' do
      it 'returns true when glow is available' do
        allow(utils).to receive(:system).with('command -v glow > /dev/null 2>&1').and_return(true)
        expect(utils.glow_available?).to be true
      end

      it 'returns false when glow is not available' do
        allow(utils).to receive(:system).with('command -v glow > /dev/null 2>&1').and_return(false)
        expect(utils.glow_available?).to be false
      end
    end

    describe '#vim_available?' do
      it 'returns true when vim is available' do
        allow(utils).to receive(:system).with('command -v vim > /dev/null 2>&1').and_return(true)
        expect(utils.vim_available?).to be true
      end
    end
  end
end
