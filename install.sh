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
    echo "           sudo yum install ruby (RHEL/CentOS)"
    exit 1
fi

RUBY_VERSION=$(ruby -v)
echo "✅ Ruby found: $RUBY_VERSION"

# Check if curses gem is available (usually part of stdlib)
if ! ruby -e "require 'curses'" 2>/dev/null; then
    echo "⚠️  Warning: Ruby curses library not found"
    echo "   Attempting to install..."

    if [[ "$PLATFORM" == "Linux" ]]; then
        echo "   You may need to install: sudo apt-get install libncurses-dev"
    fi

    gem install curses || {
        echo "❌ Failed to install curses gem"
        echo "   On Linux, you may need: sudo apt-get install libncurses-dev ruby-dev"
        echo "   On macOS, curses should be available by default"
        exit 1
    }
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
echo "📋 Copying sgt.rb to $INSTALL_DIR/sgt..."
$SUDO cp "$SCRIPT_DIR/sgt.rb" "$INSTALL_DIR/sgt"
$SUDO chmod +x "$INSTALL_DIR/sgt"

echo "✅ Binary installed"

# Check if install dir is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "⚠️  Warning: $INSTALL_DIR is not in your PATH"
    echo "   Add this line to your shell config:"
    echo "   export PATH=\"$INSTALL_DIR:\$PATH\""
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
        # Check if already installed
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

# Try to configure detected shell
CONFIGURED=false

if [[ "$USER_SHELL" == "bash" ]]; then
    add_shell_integration "$HOME/.bashrc" "Bash" && CONFIGURED=true
elif [[ "$USER_SHELL" == "zsh" ]]; then
    add_shell_integration "$HOME/.zshrc" "Zsh" && CONFIGURED=true
fi

# Offer to configure other shells
echo ""
read -p "   Configure for other shells? [y/N]: " CONFIG_OTHER
if [[ "$CONFIG_OTHER" =~ ^[Yy]$ ]]; then
    [ -f "$HOME/.bashrc" ] && add_shell_integration "$HOME/.bashrc" "Bash"
    [ -f "$HOME/.zshrc" ] && add_shell_integration "$HOME/.zshrc" "Zsh"
    [ -f "$HOME/.config/fish/config.fish" ] && {
        echo "   ⚠️  Fish shell detected - manual configuration needed"
        echo "      Add this to ~/.config/fish/config.fish:"
        echo "      function sgt"
        echo "          set selected_dir (command sgt 2>/dev/null)"
        echo "          if test -n \"\$selected_dir\" -a -d \"\$selected_dir\""
        echo "              cd \"\$selected_dir\""
        echo "              ls -lah"
        echo "          end"
        echo "      end"
    }
fi

echo ""
echo "✨ Installation complete!"
echo ""
echo "🎖️  Usage:"
echo "   1. Restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
echo "   2. Type 'sgt' in any directory"
echo "   3. Use arrow keys (↑↓) or j/k to navigate"
echo "   4. Press Enter to cd into a directory"
echo "   5. Press 'h' to go up one level"
echo "   6. Press 'l' or Space to enter a directory"
echo "   7. Press 'q' or ESC to quit"
echo ""
echo "📚 Tips:"
echo "   - Files are shown but grayed out (future: execution support)"
echo "   - Works in any directory you navigate to"
echo "   - After selecting, it will cd and show contents"
echo ""
echo "🚀 Try it now: sgt"
echo ""

