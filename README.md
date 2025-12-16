# 🎖️ Sergeant (sgt)

![Sergeant Logo](./logo.svg)

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

### File Operations
- 📋 **Copy/Cut/Paste** - Mark files with spacebar, copy (c), cut (x), and paste (p)
- ✂️  **Multi-file Selection** - Mark multiple files/folders for batch operations
- 🗑️  **Delete with Confirmation** - Safe deletion with confirmation dialog
- ✏️  **Rename** - Rename files and folders with pre-filled input
- 🔄 **Conflict Resolution** - Smart handling of file conflicts (skip/overwrite/rename)
- 📄 **File Preview** - View markdown files with glow, code files with vim/nano

### Search & Productivity
- 🔎 **Fuzzy Search** - Integrate with fzf for fast file finding
- ❓ **Help Modal** - Press 'm' for comprehensive key mapping reference
- 🚀 **Instant CD** - Select and change directory in one smooth motion

## 📋 Requirements

- **Ruby** 2.7 or higher (Ruby 3.x recommended)
- **ncurses library** (system dependency)
  - macOS: Included by default
  - Linux: `sudo apt-get install libncurses-dev` (if needed)

### Optional Tools
- **glow** - For beautiful markdown preview (`brew install glow` or `go install github.com/charmbracelet/glow@latest`)
- **fzf** - For fuzzy file search (`brew install fzf` or `sudo apt-get install fzf`)

## 🚀 Installation

### Install from RubyGems (Coming Soon)

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

# Navigate and select
# Arrow keys or j/k to move up/down
# Enter or l to enter directory
# h to go back
# q to quit and cd to selected directory
```

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
| `v` | Preview file (markdown/code) |

### Other Commands

| Key | Action |
|-----|--------|
| `↑/k` | Move up |
| `↓/j` | Move down |
| `Enter/→/l` | Open directory or preview file |
| `←/h` | Go to parent directory |
| `o` | Toggle ownership/permissions display |
| `b` | Go to bookmark |
| `/` | Search files (requires fzf) |
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
