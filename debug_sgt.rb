#!/usr/bin/env ruby
# frozen_string_literal: true

require 'curses'
include Curses

puts "Starting debug test..."
puts "Press Ctrl+C to exit"
sleep 1

begin
  # Test 1: Basic init
  puts "Test 1: Initializing screen..."
  init_screen
  puts "✓ init_screen successful"
  sleep 1

  # Test 2: Screen size
  setpos(0, 0)
  addstr("Screen size: #{lines}x#{cols}")
  refresh
  sleep 2

  # Test 3: Color support
  if start_color
    addstr("\nColors supported: #{has_colors?}")
    refresh
    sleep 2

    # Test 4: Create color pairs
    init_pair(1, COLOR_CYAN, COLOR_BLACK)
    init_pair(2, COLOR_WHITE, COLOR_BLACK)

    setpos(3, 0)
    attron(color_pair(1)) do
      addstr("This text should be CYAN")
    end
    refresh
    sleep 2
  else
    addstr("\nNo color support!")
    refresh
    sleep 2
  end

  # Test 5: Unicode
  setpos(5, 0)
  addstr("Unicode test: 📁 📄 ▶ ✓")
  refresh
  sleep 2

  # Test 6: Input
  setpos(7, 0)
  addstr("Press any key to continue (or wait 3s)...")
  refresh

  timeout(3000)  # 3 second timeout
  getch

  setpos(8, 0)
  addstr("Key pressed! Exiting...")
  refresh
  sleep 1

rescue StandardError => e
  close_screen
  puts "\n❌ Error: #{e.message}"
  puts e.backtrace.first(5)
  exit 1
ensure
  close_screen
  puts "\n✓ Test complete"
end
