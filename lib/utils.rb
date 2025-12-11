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
    rescue
      nil
    end

    def get_owner_info(stat)
      begin
        user = Etc.getpwuid(stat.uid).name
      rescue
        user = stat.uid.to_s
      end
      
      begin
        group = Etc.getgrgid(stat.gid).name
      rescue
        group = stat.gid.to_s
      end
      
      "#{user}:#{group}"
    end

    def format_permissions(mode, is_directory)
      type = is_directory ? 'd' : '-'
      
      owner = ''
      owner += (mode & 0400) != 0 ? 'r' : '-'
      owner += (mode & 0200) != 0 ? 'w' : '-'
      owner += (mode & 0100) != 0 ? 'x' : '-'
      
      group = ''
      group += (mode & 0040) != 0 ? 'r' : '-'
      group += (mode & 0020) != 0 ? 'w' : '-'
      group += (mode & 0010) != 0 ? 'x' : '-'
      
      other = ''
      other += (mode & 0004) != 0 ? 'r' : '-'
      other += (mode & 0002) != 0 ? 'w' : '-'
      other += (mode & 0001) != 0 ? 'x' : '-'
      
      "#{type}#{owner}#{group}#{other}"
    end

    def format_size(bytes)
      return "     " if bytes.nil?
      
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
      return "" if time.nil?
      time.strftime("%b %d %H:%M")
    end

    def fzf_available?
      system('command -v fzf > /dev/null 2>&1')
    end
  end
end

