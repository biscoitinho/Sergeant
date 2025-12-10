# 🎖️ Sergeant (sgt)

![Sergeant Logo](./logo.svg)

**Interactive TUI Directory Navigator for Terminal**

Sergeant is a lightweight, interactive terminal user interface (TUI) for navigating directories. Instead of typing `cd` commands, just run `sgt`, use arrow keys to select a directory, and press Enter. Simple, fast, and elegant.

## ✨ Features

- 🗂️  **Visual Directory Navigation** - See all directories and files at a glance
- ⌨️  **Keyboard Driven** - Arrow keys, vim bindings (hjkl), and shortcuts
- 🎨 **Color-Coded Display** - Directories in cyan, files grayed out
- 📊 **Smart Scrolling** - Handles directories with hundreds of items
- 🔍 **Parent Navigation** - Quickly move up directory levels with `h`
- 🚀 **Instant CD** - Select and change directory in one smooth motion
- 🍎 **Cross-Platform** - Works on macOS and Linux
- 💎 **Pure Ruby** - No external dependencies (uses stdlib curses)

## 📋 Requirements

- **Ruby** 2.5 or higher (Ruby 3.x supported)
- **curses gem**
  - Ruby 2.x: Usually included in stdlib
  - Ruby 3.x: Install with `gem install curses` (installer handles this)
- **ncurses library** (system dependency)
  - macOS: Included by default
  - Linux: `sudo apt-get install libncurses-dev` (if needed)

## 🚀 Installation

### Quick Install

```bash
cd sergeant
./install.sh

