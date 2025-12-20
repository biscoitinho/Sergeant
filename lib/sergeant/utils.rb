# frozen_string_literal: true

# Utility functions for formatting and file operations

module Sergeant
  module Utils
    def get_git_branch
      return nil unless Dir.exist?(File.join(@current_dir, '.git'))

      head_file = File.join(@current_dir, '.git', 'HEAD')
      return nil unless File.exist?(head_file)

      head_content = File.read(head_file).strip
      if head_content.start_with?('ref: refs/heads/')
        head_content.sub('ref: refs/heads/', '')
      else
        head_content[0..7]
      end
    rescue StandardError
      nil
    end

    def get_owner_info(stat)
      begin
        user = Etc.getpwuid(stat.uid).name
      rescue StandardError
        user = stat.uid.to_s
      end

      begin
        group = Etc.getgrgid(stat.gid).name
      rescue StandardError
        group = stat.gid.to_s
      end

      "#{user}:#{group}"
    end

    def format_permissions(mode, is_directory)
      type = is_directory ? 'd' : '-'

      owner = ''
      owner += mode.anybits?(0o400) ? 'r' : '-'
      owner += mode.anybits?(0o200) ? 'w' : '-'
      owner += mode.anybits?(0o100) ? 'x' : '-'

      group = ''
      group += mode.anybits?(0o040) ? 'r' : '-'
      group += mode.anybits?(0o020) ? 'w' : '-'
      group += mode.anybits?(0o010) ? 'x' : '-'

      other = ''
      other += mode.anybits?(0o004) ? 'r' : '-'
      other += mode.anybits?(0o002) ? 'w' : '-'
      other += mode.anybits?(0o001) ? 'x' : '-'

      "#{type}#{owner}#{group}#{other}"
    end

    def format_size(bytes)
      return '     ' if bytes.nil?

      if bytes < 1024
        "#{bytes}B".rjust(7)
      elsif bytes < 1024 * 1024
        "#{(bytes / 1024.0).round(1)}K".rjust(7)
      elsif bytes < 1024 * 1024 * 1024
        "#{(bytes / (1024.0 * 1024)).round(1)}M".rjust(7)
      else
        "#{(bytes / (1024.0 * 1024 * 1024)).round(1)}G".rjust(7)
      end
    end

    def format_date(time)
      return '' if time.nil?

      time.strftime('%b %d %H:%M')
    end

    def fzf_available?
      system('command -v fzf > /dev/null 2>&1')
    end

    def glow_available?
      system('command -v glow > /dev/null 2>&1')
    end

    def nvim_available?
      system('command -v nvim > /dev/null 2>&1')
    end

    def vim_available?
      system('command -v vim > /dev/null 2>&1')
    end

    def vi_available?
      system('command -v vi > /dev/null 2>&1')
    end

    def nano_available?
      system('command -v nano > /dev/null 2>&1')
    end

    def text_file?(file_path)
      return false unless File.file?(file_path)
      return false unless File.readable?(file_path)

      # Check file size - limit to 50MB for safety
      return false if File.size(file_path) > 50 * 1024 * 1024

      # Check if it's a binary file by reading first 8KB
      File.open(file_path, 'rb') do |f|
        sample = f.read(8192) || ''
        # Check for null bytes (common in binary files)
        !sample.bytes.include?(0)
      end
    rescue StandardError
      false
    end
  end
end
