# 🎖️ Sergeant (sgt)

![Sergeant Logo](./logo.svg)
![highlight](./highlight.gif)

**Interactive TUI Directory Navigator for Terminal - "Leave it to the Sarge!"**

Sergeant is a interactive terminal user interface (TUI) for navigating directories and managing files.
Instead of typing `cd` and file manipulation commands, just run `sgt`,
use arrow keys and keyboard shortcuts to navigate, preview, copy, move, and organize your files.
Simple, fast, and elegant.

## ✨ Features

### Navigation & Display
- 🗂️  **Visual Directory Navigation** - See all directories and files at a glance
- ⌨️  **Keyboard Driven** - Arrow keys, vim bindings (hjkl), and shortcuts
- 🎨 **Color-Coded Display** - Directories in cyan, files grayed out
- 📊 **Smart Scrolling** - Handles directories with hundreds of items
- 🔍 **Git Branch Display** - Shows current git branch in header
- 👤 **Ownership Toggle** - View file permissions and ownership (press 'o')
- 📑 **Bookmarks** - Save and quickly navigate to favorite directories
- 🔎 **Quick Filter** - Filter current directory view in real-time (press 'f')

### File Operations
- 📋 **Copy/Cut/Paste** - Mark files with spacebar, copy (c), cut (x), and paste (p)
- ✂️  **Multi-file Selection** - Mark multiple files/folders for batch operations
- 📏 **Size Display** - See total size of marked items in status bar
- 🗑️  **Delete with Confirmation** - Safe deletion with confirmation dialog
- ✏️  **Rename** - Rename files and folders with pre-filled input
- 🔄 **Conflict Resolution** - Smart handling of file conflicts (skip/overwrite/rename)
- 📄 **File Preview** - View markdown with glow, code with vim/nano, peek inside archives
- 📦 **Archive Peek** - Preview contents of .zip, .tar.gz, .7z, .rar files without extracting

### Search & Productivity
- 🔎 **Fuzzy Search** - Integrate with fzf for fast file finding
- ❓ **Help Modal** - Press 'm' for comprehensive key mapping reference
- 🚀 **Instant CD** - Select and change directory in one smooth motion

### Performance & Session Management
- ⚡ **Stat Caching** - Blazing fast navigation with intelligent file stat caching
- 💾 **Session Persistence** - Continue exactly where you left off with `--restore`
- 📚 **Directory History** - Quick access to your 50 most recent locations (press 'H')
- 🔄 **Smart Cache Management** - Automatic memory optimization and manual refresh

## 📋 Requirements

- **Ruby** 2.7 or higher (Ruby 3.x recommended)

### System Dependencies

The `curses` gem (installed automatically) requires native libraries:

**macOS:**
```bash
# Usually works out of the box
# If you get errors, install Xcode Command Line Tools:
xcode-select --install

# Recommended: Use Homebrew Ruby instead of system Ruby
brew install ruby
# Add to ~/.zshrc: export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
```

**Linux (Debian/Ubuntu):**
```bash
sudo apt-get install libncurses-dev ruby-dev
```

**Linux (Fedora/RHEL):**
```bash
sudo dnf install ncurses-devel ruby-devel
```

### Optional Tools
- **glow** - For beautiful markdown preview (`brew install glow` or `go install github.com/charmbracelet/glow@latest`)
- **fzf** - For fuzzy file search (`brew install fzf` or `sudo apt-get install fzf`)
- **Archive tools** - For archive preview: `unzip`, `tar`, `7z`, `unrar` (usually pre-installed on most systems)

## 🚀 Installation

### Install from RubyGems

Once published to RubyGems:

```bash
gem install sergeant
```

### Install from Source

```bash
# Clone the repository
git clone https://github.com/biscoitinho/Sergeant.git
cd Sergeant

# Build and install the gem locally
gem build sergeant.gemspec
gem install ./sergeant-1.0.0.gem
```

That's it! The `sgt` command will automatically be added to your PATH.

### Troubleshooting Installation

**If sgt doesn't display anything (shows blank screen):**

This can happen on Arch Linux or other systems using Ruby version managers (mise, rbenv, asdf).

**Recommended fix - Add an alias (simplest):**
```bash
# Add to your ~/.bashrc or ~/.zshrc:
echo 'alias sgt='"'"'ruby "$(which sgt)"'"'"'' >> ~/.bashrc

# Reload your shell:
source ~/.bashrc  # or: source ~/.zshrc

# Now sgt works!
sgt
```

**Alternative - Quick test:**
```bash
# Run with explicit ruby (temporary fix)
ruby $(which sgt)
```
### Development Installation

If you want to work on the gem:

```bash
# Clone and setup
git clone https://github.com/biscoitinho/Sergeant.git
cd Sergeant

# Install dependencies
bundle install

# Run directly without installing
bundle exec bin/sgt
```

## 🎮 Usage

### Basic Navigation

```bash
# Start sergeant in current directory
sgt

# Start in specific directory
sgt ~/Documents

# Start at a bookmark
sgt -b projects

# Navigate and select
# Arrow keys or j/k to move up/down
# Enter or l to enter directory
# h to go back
# q to quit and cd to selected directory
```

### Command-Line Options

```bash
# View help and all options
sgt --help

# Show version
sgt --version

# List all bookmarks
sgt --list-bookmarks

# Start at bookmark location
sgt -b [bookmark_name]

# Restore last session (continue from where you left off)
sgt --restore

# Debug mode (show environment info)
sgt --debug

# Disable colors
sgt --no-color
```

### Shell Integration (cd to final directory)

The `--pwd` flag enables powerful shell integration, allowing you to navigate visually in sergeant and have your shell automatically cd to the final location:

```bash
# Quick navigation function
# Add this to your ~/.bashrc or ~/.zshrc:
s() {
  local dir=$(sgt --pwd "$@")
  [[ -n "$dir" ]] && cd "$dir"
}

# Usage examples:
s                    # Navigate from current dir, cd to final location
s ~/projects         # Start in projects, cd to where you end up
s -b work            # Start at work bookmark, cd to final location

# Alternative one-liner (no function needed):
cd $(sgt --pwd ~/projects)

# Jump to deeply nested directory visually:
cd $(sgt --pwd /usr/local)
```

**How it works:**
1. Start sergeant with `--pwd` flag
2. Navigate to your desired directory using arrow keys
3. Press `q` to quit
4. Sergeant outputs the final directory path
5. Shell captures it with `$()` and cd's there

### Performance & Productivity Features

#### ⚡ Stat Caching

Sergeant intelligently caches file system metadata for lightning-fast navigation:

- **What it does:** Caches `File.stat()` results for 5 seconds to avoid redundant system calls
- **Performance impact:** 90%+ faster when browsing back and forth between directories
- **How it works:** First visit fetches file stats normally, subsequent visits within 5 seconds use cached data
- **Memory management:** Automatically limits cache to 5000 entries, removing oldest entries when exceeded
- **Especially beneficial for:**
  - Large directories (hundreds or thousands of files)
  - Network filesystems (NFS, SMB, SSHFS)
  - Frequent navigation between the same directories
- **Manual control:** Press `R` to force refresh and clear cache at any time

```bash
# Example: Navigate large directory trees with near-zero lag
cd /usr/local/lib
sgt
# Navigate in/out of directories rapidly - cached stats make it instant!
```

#### 💾 Session Persistence

Never lose your place when closing the terminal:

- **What it does:** Automatically saves your current directory when you quit sergeant
- **Saved to:** `~/.sgt_session` file in your home directory
- **How to use:** Start sergeant with `--restore` flag to continue from last location
- **Perfect for:**
  - Resuming work after restarting terminal
  - Working in deeply nested directory structures
  - Quick session recovery after system updates

```bash
# Navigate to deeply nested project directory
sgt ~/work/projects/client-name/backend/src/controllers
# ... work in sergeant, press q to quit

# Later, restore exactly where you were:
sgt --restore
# You're back in ~/work/projects/client-name/backend/src/controllers

# Add alias for convenience:
alias sgtl='sgt --restore'  # "sergeant last"
```

#### 📚 Directory History

Quick access to your recently visited locations:

- **What it does:** Tracks the last 50 directories you've visited in sergeant
- **Saved to:** `~/.sgt_history` file (persistent across sessions)
- **How to use:** Press `H` to open the history modal
- **Features:**
  - Navigate with ↑/↓ arrow keys or j/k vim bindings
  - Press Enter to jump directly to any directory
  - Most recent directories appear first
  - Automatic deduplication (no repeated entries)
  - Validates directory still exists before jumping

```bash
# During your session:
# Visit: ~/projects → ~/documents → /tmp → ~/downloads
# Press 'H' to see history modal:
#   1. ~/downloads      (most recent)
#   2. /tmp
#   3. ~/documents
#   4. ~/projects
# Use arrows to select, Enter to jump back to any location
```

**Workflow example:**
```bash
# Morning: work on multiple projects
sgt ~/projects/web-app         # Visit project 1
# ... navigate around ...
sgt ~/projects/mobile-app      # Visit project 2
# ... work on files ...
sgt ~/documents/specs          # Check documentation

# Afternoon: quickly return to any location
sgt
# Press 'H' → see all morning locations
# Select ~/projects/web-app → instant return!
```

#### 🔄 Smart Cache Management

Sergeant automatically manages memory and provides manual control:

- **Automatic cleanup:** When cache exceeds 5000 entries, oldest entries are removed
- **Manual refresh:** Press `R` to force refresh and clear all cached data
- **Use cases for manual refresh:**
  - Files modified by external programs
  - Network filesystem changes
  - Want to see real-time updates
  - Debugging file system issues

### File Operations

| Key | Action |
|-----|--------|
| `Space` | Mark/unmark item for operations |
| `c` | Copy marked items |
| `x` | Cut marked items |
| `p` | Paste copied/cut items |
| `d` | Delete marked items (with confirmation) |
| `r` | Rename current item |
| `u` | Unmark all items |
| `n` | Create new file or directory |
| `e` | Edit file with $EDITOR (or nano/nvim/vim) |
| `v` | Preview file or archive contents |

### Other Commands

| Key | Action |
|-----|--------|
| `↑/k` | Move up |
| `↓/j` | Move down |
| `Enter/→/l` | Open directory or preview file |
| `←/h` | Go to parent directory |
| `f` | Filter current directory view |
| `/` | Search files (requires fzf) |
| `:` | Execute terminal command in current directory |
| `o` | Toggle ownership/permissions display |
| `b` | Go to bookmark |
| `H` | Show recent directories history |
| `R` | Force refresh and clear cache |
| `m` | Show help modal with all key mappings |
| `q/ESC` | Quit and cd to current directory |

## ⚙️ Configuration

Create a `~/.sgtrc` file to customize colors and bookmarks:

```ini
# Color theme (available: black, red, green, yellow, blue, magenta, cyan, white)
[colors]
directories=cyan
files=white
selected_bg=blue
selected_fg=black
header=yellow
path=green
git_branch=magenta

# Bookmarks
[bookmarks]
home=/home/user
projects=~/projects
documents=~/Documents
```

## 🧪 Development

### Running Tests

```bash
# Install development dependencies
bundle install

# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/utils_spec.rb

# Run with documentation format
bundle exec rspec --format documentation
```

### Code Quality

```bash
# Run rubocop linter
bundle exec rubocop

# Auto-correct issues
bundle exec rubocop -A
```

### Project Structure

```
sergeant/
├── bin/
│   └── sgt                   # Executable command
├── lib/
│   ├── sergeant.rb           # Main application class
│   └── sergeant/
│       ├── version.rb        # Gem version
│       ├── config.rb         # Configuration and bookmark management
│       ├── utils.rb          # Utility functions (formatting, file detection)
│       ├── rendering.rb      # UI rendering and display logic
│       ├── modals.rb         # Modal modules loader
│       └── modals/           # Modal dialog modules
│           ├── navigation.rb       # Bookmark navigation
│           ├── dialogs.rb          # Info/error/confirmation dialogs
│           ├── file_operations.rb  # File preview, copy, paste, delete, rename
│           └── help.rb             # Help modal with key mappings
├── spec/                     # RSpec test suite
├── sergeant.gemspec          # Gem specification
├── Gemfile                   # Bundler configuration
└── README.md                 # This file
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
Be warn, that I reserve my personal judgement to new features
as I'm very focused on not to bloat it with too many functionalities

## 📝 License

MIT License

## 🙏 Acknowledgments

- Built with Ruby and ncurses
- Inspired by [Omarchy linux](https://omarchy.org) and terminal file managers like ranger and nnn
- Uses [glow](https://github.com/charmbracelet/glow) for markdown rendering
- Integrates with [fzf](https://github.com/junegunn/fzf) for fuzzy finding

---

**"Leave it to the Sarge!"** 🎖️
