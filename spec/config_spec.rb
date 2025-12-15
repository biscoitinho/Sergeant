# frozen_string_literal: true

require 'curses'
require_relative '../lib/config'

RSpec.describe Sergeant::Config do
  describe '.load_config' do
    it 'returns default config when no file exists' do
      allow(File).to receive(:exist?).and_return(false)
      config = described_class.load_config
      expect(config).to be_a(Hash)
      expect(config['directories']).to eq('cyan')
      expect(config['files']).to eq('white')
    end

    it 'merges user config with defaults' do
      config_content = <<~CONFIG
        [colors]
        directories=green
      CONFIG

      config_file = File.join(Dir.home, '.sgtrc')
      allow(File).to receive(:exist?).with(config_file).and_return(true)
      allow(File).to receive(:readlines).with(config_file).and_return(config_content.lines)

      config = described_class.load_config
      expect(config['directories']).to eq('green')
      expect(config['files']).to eq('white') # Still default
    end

    it 'handles invalid config gracefully' do
      config_file = File.join(Dir.home, '.sgtrc')
      allow(File).to receive(:exist?).with(config_file).and_return(true)
      allow(File).to receive(:readlines).with(config_file).and_raise(StandardError)

      config = described_class.load_config
      expect(config).to eq(described_class::DEFAULT_CONFIG)
    end
  end

  describe '.load_bookmarks' do
    it 'returns empty hash when no config file exists' do
      allow(File).to receive(:exist?).and_return(false)
      bookmarks = described_class.load_bookmarks
      expect(bookmarks).to eq({})
    end

    it 'loads bookmarks from config file' do
      config_content = <<~CONFIG
        [bookmarks]
        home=/home/user
        projects=/home/user/projects
      CONFIG

      config_file = File.join(Dir.home, '.sgtrc')
      allow(File).to receive(:exist?).with(config_file).and_return(true)
      allow(File).to receive(:readlines).with(config_file).and_return(config_content.lines)

      bookmarks = described_class.load_bookmarks
      expect(bookmarks).to eq({
                                'home' => '/home/user',
                                'projects' => '/home/user/projects'
                              })
    end

    it 'expands ~ in bookmark paths' do
      config_content = <<~CONFIG
        [bookmarks]
        home=~/Documents
      CONFIG

      config_file = File.join(Dir.home, '.sgtrc')
      allow(File).to receive(:exist?).with(config_file).and_return(true)
      allow(File).to receive(:readlines).with(config_file).and_return(config_content.lines)

      bookmarks = described_class.load_bookmarks
      expect(bookmarks['home']).to eq(File.expand_path('~/Documents'))
    end

    it 'ignores invalid bookmark lines' do
      config_content = <<~CONFIG
        [bookmarks]
        home=/home/user
        invalid_line_without_equals
        projects=/home/user/projects
      CONFIG

      config_file = File.join(Dir.home, '.sgtrc')
      allow(File).to receive(:exist?).with(config_file).and_return(true)
      allow(File).to receive(:readlines).with(config_file).and_return(config_content.lines)

      bookmarks = described_class.load_bookmarks
      expect(bookmarks.keys).to contain_exactly('home', 'projects')
    end

    it 'handles empty bookmarks section' do
      config_content = <<~CONFIG
        [colors]
        directories=cyan
        [bookmarks]
      CONFIG

      config_file = File.join(Dir.home, '.sgtrc')
      allow(File).to receive(:exist?).with(config_file).and_return(true)
      allow(File).to receive(:readlines).with(config_file).and_return(config_content.lines)

      bookmarks = described_class.load_bookmarks
      expect(bookmarks).to eq({})
    end
  end

  describe '.get_color' do
    it 'maps color names to curses constants' do
      expect(described_class.get_color('black')).to eq(Curses::COLOR_BLACK)
      expect(described_class.get_color('red')).to eq(Curses::COLOR_RED)
      expect(described_class.get_color('green')).to eq(Curses::COLOR_GREEN)
      expect(described_class.get_color('yellow')).to eq(Curses::COLOR_YELLOW)
      expect(described_class.get_color('blue')).to eq(Curses::COLOR_BLUE)
      expect(described_class.get_color('magenta')).to eq(Curses::COLOR_MAGENTA)
      expect(described_class.get_color('cyan')).to eq(Curses::COLOR_CYAN)
      expect(described_class.get_color('white')).to eq(Curses::COLOR_WHITE)
    end

    it 'returns white for unknown colors' do
      expect(described_class.get_color('purple')).to eq(Curses::COLOR_WHITE)
      expect(described_class.get_color('invalid')).to eq(Curses::COLOR_WHITE)
    end

    it 'is case insensitive' do
      expect(described_class.get_color('RED')).to eq(Curses::COLOR_RED)
      expect(described_class.get_color('Blue')).to eq(Curses::COLOR_BLUE)
    end
  end

  describe 'DEFAULT_CONFIG constant' do
    it 'returns a hash with all required keys' do
      config = described_class::DEFAULT_CONFIG
      expect(config).to include(
        'directories',
        'files',
        'selected_fg',
        'selected_bg',
        'header',
        'path',
        'git_branch'
      )
    end

    it 'returns reasonable default colors' do
      config = described_class::DEFAULT_CONFIG
      expect(config['directories']).to eq('cyan')
      expect(config['files']).to eq('white')
      expect(config['selected_bg']).to eq('cyan')
    end
  end
end
