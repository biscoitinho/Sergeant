# Changelog

All notable changes to Sergeant will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2024-12-24

### Fixed
- **Major performance improvement**: Fixed severe input lag with large directories
  - Directory contents now only refresh when necessary (directory changes, file operations)
  - Previously refreshed on every keystroke, causing thousands of unnecessary file system calls
  - Navigation (arrow keys, marking) is now instant regardless of directory size
- **Better error handling**: Added error messages to help diagnose installation issues
  - Shows load path and helpful reinstall instructions if gem fails to load
  - Displays full error details instead of silently failing

## [1.0.0] - 2024-12-23

### Added
- **Interactive TUI navigation** - Navigate directories with arrow keys or vim bindings (hjkl)
- **File operations**
  - Mark/unmark files with Space
  - Copy (c), cut (x), paste (p) with smart conflict resolution
  - Delete with confirmation (d)
  - Rename files/directories (r)
  - Create new files/directories (n)
- **File viewing and editing**
  - Edit files with $EDITOR support (e) - respects POSIX conventions
  - Preview files read-only (v) - markdown with glow, code with nvim/vim
  - Fallback chain: $EDITOR → nano → nvim → vim → vi
- **Terminal integration**
  - Execute shell commands without leaving sgt (:)
  - Commands run in current directory context
- **Search and navigation**
  - Fuzzy file search with fzf integration (/)
  - Bookmarks system (b)
  - Git branch display in header
  - Parent directory navigation (h/←)
- **UI features**
  - Color-coded display (directories, files, selected items)
  - Adaptive interface for narrow terminals and tiling window managers
  - Smart scrolling for large directories
  - Ownership/permissions toggle (o)
  - Help modal with all key mappings (m)
  - Status indicators for marked/copied items
- **Configuration**
  - Customizable colors via ~/.sgtrc
  - Bookmark management in config file
  - Theme support

### Technical
- Built as Ruby gem for easy installation
- POSIX-compliant, respects environment variables ($EDITOR, $VISUAL)
- Ncurses-based TUI
- Comprehensive test suite with RSpec
- No GUI dependencies - works in pure terminal

[1.0.0]: https://github.com/biscoitinho/Sergeant/releases/tag/v1.0.0
