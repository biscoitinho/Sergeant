#!/bin/bash
# Sergeant Installation Script
# Supports macOS and Linux

set -e

echo "🎖️  Installing Sergeant (sgt) - Interactive Directory Navigator"
echo ""

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     PLATFORM=Linux;;
    Darwin*)    PLATFORM=Mac;;
    *)          PLATFORM="UNKNOWN:${OS}"
esac

echo "📍 Detected platform: $PLATFORM"

# Check if Ruby is installed
if ! command -v ruby &> /dev/null; then
    echo "❌ Error: Ruby is not installed"
    echo "   Please install Ruby first:"
    echo "   - macOS: brew install ruby"
    echo "   - Linux: sudo apt-get install ruby (Debian/Ubuntu)"
    exit 1
fi

RUBY_VERSION=$(ruby -v)
echo "✅ Ruby found: $RUBY_VERSION"

# Check if curses gem is available
if ! ruby -e "require 'curses'" 2>/dev/null; then
    echo "⚠️  Warning: Ruby curses library not found"
    echo "   Attempting to install..."

    if [[ "$PLATFORM" == "Linux" ]]; then
        echo "   You may need to install: sudo apt-get install libncurses-dev ruby-dev"
    fi

    gem install curses || {
        echo "❌ Failed to install curses gem"
        echo "   On Linux, you may need: sudo apt-get install libncurses-dev ruby-dev"
        echo "   On macOS, curses should be available by default"
        exit 1
    }
fi

# Check if we need to build
if [ ! -f "sgt" ] || [ "sgt.rb" -nt "sgt" ]; then
    echo ""
    echo "🔨 Building single file executable..."
    ruby build.rb
fi

echo ""
echo "📂 Installation options:"
echo "   1. User install (recommended) - ~/.local/bin"
echo "   2. System install - /usr/local/bin (requires sudo)"
read -p "Choose option [1]: " INSTALL_OPTION
INSTALL_OPTION=${INSTALL_OPTION:-1}

if [[ "$INSTALL_OPTION" == "1" ]]; then
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
    SUDO=""
    echo "📁 Installing to: $INSTALL_DIR (user)"
elif [[ "$INSTALL_OPTION" == "2" ]]; then
    INSTALL_DIR="/usr/local/bin"
    SUDO="sudo"
    echo "📁 Installing to: $INSTALL_DIR (system)"
else
    echo "❌ Invalid option"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy and make executable
echo "📋 Copying sgt to $INSTALL_DIR/sgt..."
$SUDO cp "$SCRIPT_DIR/sgt" "$INSTALL_DIR/sgt"
$SUDO chmod +x "$INSTALL_DIR/sgt"

echo "✅ Binary installed"

# Check if install dir is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "⚠️  Warning: $INSTALL_DIR is not in your PATH"
    echo "   Add this line to your shell config:"
    echo "   export PATH=\"$INSTALL_DIR:\$PATH\""
fi

# Handle config file
CONFIG_FILE="$HOME/.sgtrc"
if [ ! -f "$CONFIG_FILE" ]; then
    echo ""
    echo "📝 Config file setup:"
    read -p "   Create config from example? [Y/n]: " CREATE_CONFIG
    CREATE_CONFIG=${CREATE_CONFIG:-Y}
    
    if [[ "$CREATE_CONFIG" =~ ^[Yy]$ ]]; then
        if [ -f "$SCRIPT_DIR/.sgtrc.example" ]; then
            cp "$SCRIPT_DIR/.sgtrc.example" "$CONFIG_FILE"
            echo "   ✓ Created ~/.sgtrc from example"
        else
            echo "   ⚠️  .sgtrc.example not found, minimal config will be auto-created on first run"
        fi
    else
        echo "   ⊘ Skipped - minimal config will be auto-created on first run"
    fi
else
    echo ""
    echo "📝 Config: Using existing ~/.sgtrc"
fi

# Create shell function
SHELL_FUNCTION='
# Sergeant - Interactive directory navigator
sgt() {
    local selected_dir
    selected_dir=$(command sgt 2>/dev/null)
    local exit_code=$?

    if [ $exit_code -eq 0 ] && [ -n "$selected_dir" ] && [ -d "$selected_dir" ]; then
        cd "$selected_dir" || return 1
        # Optional: list directory after cd
        ls -lah
    fi
}
'

echo ""
echo "🐚 Shell integration:"
echo ""

# Detect user's shell
USER_SHELL=$(basename "$SHELL")

# Function to add shell integration
add_shell_integration() {
    local shell_config=$1
    local shell_name=$2

    if [ -f "$shell_config" ]; then
        if grep -q "# Sergeant - Interactive directory navigator" "$shell_config" 2>/dev/null; then
            echo "   ✓ $shell_name: Already configured"
            return 0
        fi

        read -p "   Add function to $shell_config? [Y/n]: " ADD_TO_SHELL
        ADD_TO_SHELL=${ADD_TO_SHELL:-Y}

        if [[ "$ADD_TO_SHELL" =~ ^[Yy]$ ]]; then
            echo "$SHELL_FUNCTION" >> "$shell_config"
            echo "   ✓ $shell_name: Added to $shell_config"
            return 0
        else
            echo "   ⊘ $shell_name: Skipped"
            return 1
        fi
    fi
    return 2
}

# Configure shell
if [[ "$USER_SHELL" == "bash" ]]; then
    add_shell_integration "$HOME/.bashrc" "Bash"
elif [[ "$USER_SHELL" == "zsh" ]]; then
    add_shell_integration "$HOME/.zshrc" "Zsh"
fi

echo ""
echo "✨ Installation complete!"
echo ""
echo "🎖️  Usage:"
echo "   1. Restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
echo "   2. Type 'sgt' in any directory"
echo "   3. Use arrow keys (↑↓) or j/k to navigate"
echo "   4. Press Enter to open directory"
echo "   5. Press 'b' for bookmarks"
echo "   6. Press 'o' to toggle ownership view"
echo "   7. Press '/' to search with fzf"
echo "   8. Press 'q' or ESC to select current directory"
echo ""
echo "📝 Configuration:"
echo "   Edit ~/.sgtrc to customize colors and bookmarks"
echo "   See .sgtrc.example for all available themes"
echo ""
echo "🚀 Try it now: sgt"
echo ""

