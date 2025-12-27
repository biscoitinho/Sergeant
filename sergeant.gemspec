# frozen_string_literal: true

require_relative 'lib/sergeant/version'

Gem::Specification.new do |spec|
  spec.name          = 'sergeant'
  spec.version       = Sergeant::VERSION
  spec.authors       = ['Mateusz Grotha']
  spec.email         = ['matgrotha@gmail.com']

  spec.summary       = 'Interactive TUI Directory Navigator for Terminal'
  spec.description   = 'Sergeant (sgt) is an interactive terminal user interface (TUI) for navigating directories and managing files. Navigate with arrow keys, preview files, copy, move, and organize - all from your terminal.'
  spec.homepage      = 'https://github.com/biscoitinho/Sergeant'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/biscoitinho/Sergeant'
  spec.metadata['changelog_uri'] = 'https://github.com/biscoitinho/Sergeant/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{\A(?:test|spec|features)/}) ||
        f.match(%r{\A\.}) ||
        f.match(%r{\.DS_Store$}) ||
        f.match(%r{\.(gif|png|jpg|jpeg|mp4|webm)$}) ||  # Exclude media files
        f == 'build.rb' ||
        f == 'install.sh' ||
        f == 'sgt.rb'
    end
  end

  spec.bindir        = 'bin'
  spec.executables   = ['sgt']
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'curses', '~> 1.4'

  # Development dependencies
  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'rubocop', '~> 1.81'
end
