#!/usr/bin/env ruby
# frozen_string_literal: true

# Add lib to load path
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require 'sergeant'
require 'curses'

# Monkey-patch to add debug output
class SergeantApp
  alias_method :original_run, :run

  def run
    puts "DEBUG: Starting sgt..."
    puts "DEBUG: Current dir: #{Dir.pwd}"
    puts "DEBUG: TERM=#{ENV['TERM']}"
    puts "DEBUG: LANG=#{ENV['LANG']}"

    begin
      puts "DEBUG: Calling init_screen..."
      Curses.init_screen
      puts "DEBUG: Screen size: #{Curses.lines}x#{Curses.cols}"

      puts "DEBUG: Calling start_color..."
      Curses.start_color
      puts "DEBUG: Has colors: #{Curses.has_colors?}"

      puts "DEBUG: Setting cursor and echo..."
      Curses.curs_set(0)
      Curses.noecho
      Curses.stdscr.keypad(true)

      puts "DEBUG: Applying color theme..."
      apply_color_theme

      puts "DEBUG: Entering main loop..."
      puts "DEBUG: Press Ctrl+C to see this message"
      sleep 1

      # Call original run method (which will clear the screen)
      Curses.close_screen
      original_run

    rescue StandardError => e
      Curses.close_screen
      puts "\nDEBUG ERROR: #{e.class}: #{e.message}"
      puts e.backtrace.first(10)
      exit 1
    end
  end
end

# Run the app
app = SergeantApp.new
app.run
