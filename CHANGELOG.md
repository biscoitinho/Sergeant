# Changelog

All notable changes to Sergeant will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.4] - 2024-12-27

### Fixed
- **Windows compatibility improvements**
  - Use ASCII icons ([D], [F], *, >) on Windows for better terminal compatibility (PR #15)
  - Windows terminals often don't render emoji properly - now uses ASCII fallback
  - Add notepad fallback for file preview and edit on Windows (PR #16)
  - POSIX tools (vim, nano, less) replaced with notepad when not available

### Changed
- Reduced gem package size from 4.8MB to ~115KB by excluding media files and .DS_Store

## [1.0.3] - 2024-12-26

### Added
- **Total size display for marked items**
  - Status bar now shows total size of all marked files
  - Helps users understand the size of operations before copying/cutting
  - Automatically formatted with appropriate units (B, K, M, G)
- **Quick filter feature** (f key)
  - Filter current directory view without changing directories
  - Case-insensitive real-time filtering as you type
  - Status bar shows active filter and filtered item count
  - Press ESC to clear filter, Enter to apply
- **Archive peek support** (v key on archives)
  - Preview contents of archive files without extracting
  - Supports: .zip, .tar, .tar.gz/.tgz, .tar.bz2/.tbz, .tar.xz/.txz, .7z, .rar
  - Uses native tools (unzip, tar, 7z, unrar) for listing contents
  - Falls back gracefully if archive tools not installed
- **Command-line interface improvements**
  - Added `--help` / `-h` flag to show usage and features
  - Added `--version` / `-v` flag to show version number
  - Support starting in specific directory: `sgt ~/Documents`
  - Added `--no-color` flag for terminals without color support
  - Post-install message with quick start guide and tips

### Changed
- Updated help modal to reflect new features
- Reorganized help modal with "View & Search" section for better clarity

### Performance
- **Optimized directory refresh**
  - Only fetch owner info and permissions when ownership display is enabled
  - Use `stat.directory?` instead of `File.directory?()` to avoid duplicate syscalls
  - Track ownership toggle changes to refresh only when needed
- **Added comprehensive test coverage** for performance optimizations (14 test cases)

## [1.0.2] - 2024-12-26

### Fixed
- **Display issue on Arch Linux**: Added terminal color support checking
  - Prevents crashes on terminals without color support
  - Gracefully degrades when `start_color` is unavailable
  - Fixes blank screen issue with Ruby version managers (mise, rbenv, asdf)

### Added
- **Installation troubleshooting**
  - Comprehensive troubleshooting documentation in README
  - Simple alias solution for Arch Linux display issues: `alias sgt='ruby "$(which sgt)"'`
- **Better error handling**
  - Terminal initialization now shows helpful error messages on failure
  - Displays environment information (TERM, TTY status) to aid debugging

### Technical
- Improved terminal initialization with `has_colors?` checks before calling `start_color`
- Added error recovery for curses screen initialization failures
- Better compatibility with different ncurses implementations

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
