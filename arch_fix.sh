#!/bin/bash
# Fix for Arch Linux mise/rbenv/asdf users
# This creates a wrapper script that works around the shebang environment issue

set -e

echo "=== Sergeant Arch Linux Fix ==="
echo

# Find current installations
SGT_PATH=$(gem which sergeant 2>/dev/null | sed 's/lib\/sergeant\.rb/bin\/sgt/')
RUBY_PATH=$(which ruby)

if [ -z "$SGT_PATH" ] || [ ! -f "$SGT_PATH" ]; then
    echo "❌ Error: sergeant not found. Please install it first:"
    echo "   gem install sergeant"
    exit 1
fi

echo "Found Ruby: $RUBY_PATH"
echo "Found sgt:  $SGT_PATH"
echo

# Create wrapper directory
WRAPPER_DIR="$HOME/.local/bin"
mkdir -p "$WRAPPER_DIR"

# Create wrapper script
WRAPPER="$WRAPPER_DIR/sgt"
cat > "$WRAPPER" << 'WRAPPER_EOF'
#!/bin/bash
# Sergeant wrapper for mise/rbenv/asdf compatibility
# This ensures proper terminal environment when running via shebang

# Set terminal if not already set
export TERM="${TERM:-xterm-256color}"

# Ensure output is not buffered
export RUBY_BUFFERED=0

# Find Ruby and sgt
WRAPPER_EOF

echo "RUBY_BIN=\"$RUBY_PATH\"" >> "$WRAPPER"
echo "SGT_BIN=\"$SGT_PATH\"" >> "$WRAPPER"

cat >> "$WRAPPER" << 'WRAPPER_EOF'

# Run sgt with explicit Ruby
exec "$RUBY_BIN" "$SGT_BIN" "$@"
WRAPPER_EOF

chmod +x "$WRAPPER"

echo "✅ Created wrapper: $WRAPPER"
echo

# Check if directory is in PATH
if echo "$PATH" | grep -q "$WRAPPER_DIR"; then
    echo "✅ $WRAPPER_DIR is already in PATH"
else
    echo "⚠️  $WRAPPER_DIR is NOT in PATH"
    echo
    echo "Add this to your ~/.bashrc or ~/.zshrc:"
    echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo
    echo "Then run: source ~/.bashrc  # or source ~/.zshrc"
fi

echo
echo "=== Test ==="
echo "Run: sgt"
echo "If it doesn't work, run: $WRAPPER"
echo
echo "If still having issues, check: cat INSTALL_TROUBLESHOOTING.md"
