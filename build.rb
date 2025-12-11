#!/usr/bin/env ruby
# Build script - concatenates all files into single sgt executable

HEADER = <<~HEADER
  #!/usr/bin/env ruby
  # Sergeant (sgt) - Interactive TUI directory navigator
  # Version: 1.0.0
  # This file is auto-generated from multiple source files
  
  require 'curses'
  require 'pathname'
  require 'etc'
  
HEADER

def extract_module_content(file_path)
  content = File.read(file_path)
  # Remove require statements and shebang
  content.gsub!(/^#!\/usr\/bin\/env ruby.*$/, '')
  content.gsub!(/^require.*$/, '')
  content.gsub!(/^require_relative.*$/, '')
  content.strip
end

def build
  puts "🔨 Building Sergeant..."
  
  output = HEADER
  
  # Add lib files in order
  lib_files = [
    'lib/config.rb',
    'lib/utils.rb',
    'lib/modals.rb',
    'lib/rendering.rb'
  ]
  
  lib_files.each do |file|
    puts "  Adding #{file}..."
    output += "\n# ===== #{file} =====\n\n"
    output += extract_module_content(file)
    output += "\n"
  end
  
  # Add main file
  puts "  Adding sgt.rb..."
  output += "\n# ===== Main Application =====\n\n"
  main_content = extract_module_content('sgt.rb')
  # Remove require_relative lines from main file
  main_content.gsub!(/^require_relative.*\n/, '')
  output += main_content
  
  # Write output
  File.write('sgt', output)
  File.chmod(0755, 'sgt')
  
  puts "✅ Build complete! Single file created: sgt"
  puts "   File size: #{(File.size('sgt') / 1024.0).round(2)} KB"
end

build if __FILE__ == $0

