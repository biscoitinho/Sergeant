# frozen_string_literal: true

# Configuration and bookmark management

module Sergeant
  module Config
    COLOR_MAP = {
      'black' => Curses::COLOR_BLACK,
      'red' => Curses::COLOR_RED,
      'green' => Curses::COLOR_GREEN,
      'yellow' => Curses::COLOR_YELLOW,
      'blue' => Curses::COLOR_BLUE,
      'magenta' => Curses::COLOR_MAGENTA,
      'cyan' => Curses::COLOR_CYAN,
      'white' => Curses::COLOR_WHITE
    }.freeze

    DEFAULT_CONFIG = {
      'directories' => 'cyan',
      'files' => 'white',
      'selected_bg' => 'cyan',
      'selected_fg' => 'black',
      'header' => 'yellow',
      'path' => 'green',
      'git_branch' => 'magenta'
    }.freeze

    MINIMAL_CONFIG_TEMPLATE = <<~CONFIG.freeze
      # Sergeant Configuration File
      # Color theme (available: black, red, green, yellow, blue, magenta, cyan, white)
      directories=cyan
      files=white
      selected_bg=cyan
      selected_fg=black
      header=yellow
      path=green
      git_branch=magenta

      # Bookmarks
      [bookmarks]
      # Add your bookmarks here
      # Example:
      # home=#{Dir.home}
      # projects=~/projects
    CONFIG

    def self.load_config
      config_file = File.join(Dir.home, '.sgtrc')
      ensure_config_exists(config_file)

      config = DEFAULT_CONFIG.dup

      return config unless File.exist?(config_file)

      File.readlines(config_file).each do |line|
        line = line.strip
        next if line.empty? || line.start_with?('#')
        next if line.include?('=') && line.split('=')[0].strip.start_with?('[bookmark')

        key, value = line.split('=', 2)
        next unless key && value

        config[key.strip] = value.strip
      end

      config
    rescue StandardError
      DEFAULT_CONFIG.dup
    end

    def self.load_bookmarks
      config_file = File.join(Dir.home, '.sgtrc')
      bookmarks = {}

      return bookmarks unless File.exist?(config_file)

      in_bookmark_section = false

      File.readlines(config_file).each do |line|
        line = line.strip

        if line.downcase.include?('[bookmarks]')
          in_bookmark_section = true
          next
        end

        if line.start_with?('[') && line.end_with?(']')
          in_bookmark_section = false
          next
        end

        next if line.empty? || line.start_with?('#')

        next unless in_bookmark_section && line.include?('=')

        key, value = line.split('=', 2)
        next unless key && value

        key = key.strip
        value = value.strip.gsub('~', Dir.home)

        bookmarks[key] = File.expand_path(value) if value.start_with?('/') || value.start_with?('~') || value.include?('/')
      end

      bookmarks
    rescue StandardError
      {}
    end

    def self.ensure_config_exists(config_file)
      return if File.exist?(config_file)

      File.write(config_file, MINIMAL_CONFIG_TEMPLATE)
    end

    def self.get_color(name)
      COLOR_MAP[name.downcase] || Curses::COLOR_WHITE
    end
  end
end
