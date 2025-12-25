# Installation and Troubleshooting Guide

## Standard Installation (Works for 99% of users)

```bash
gem install sergeant
sgt
```

---

## Issue: "Nothing displays when running sgt" (Arch Linux, mise/rbenv/asdf users)

### Symptoms
- Running `ruby $(which sgt)` works
- Running `sgt` alone shows nothing
- The app is running but no display appears

### Root Cause
Ruby version managers (mise, rbenv, asdf) create executables with shebangs pointing to specific Ruby installations. When these executables run via shebang, they may not inherit the proper terminal environment.

### Solution 1: Wrapper Script (Recommended)

Create a wrapper that runs sgt with explicit environment:

```bash
# Find your sgt location
SGT_PATH=$(which sgt)
RUBY_PATH=$(which ruby)

# Create wrapper
mkdir -p ~/.local/bin
cat > ~/.local/bin/sgt << EOF
#!/bin/bash
export TERM="\${TERM:-xterm-256color}"
exec $RUBY_PATH $SGT_PATH "\$@"
EOF

chmod +x ~/.local/bin/sgt

# Make sure ~/.local/bin is in PATH
export PATH="$HOME/.local/bin:$PATH"
# Add to ~/.bashrc or ~/.zshrc to persist
```

### Solution 2: Install with System Ruby

```bash
# Temporarily disable version manager
mise deactivate  # or: rbenv shell system, or: asdf shell ruby system

# Install with system Ruby
sudo pacman -S ruby  # Arch Linux
gem install sergeant

# Test
sgt
```

### Solution 3: Fix the Binstub

Edit the generated sgt executable to add environment setup:

```bash
# Find sgt
BINSTUB=$(which sgt)

# Edit it (backup first)
cp $BINSTUB ${BINSTUB}.backup

# Add after shebang:
# ENV['TERM'] ||= 'xterm-256color'
# $stdout.sync = true
# $stderr.sync = true
```

---

## Other Common Issues

### "curses not found"

```bash
# Install curses gem
gem install curses

# On some systems, you may need dev packages first:
# Arch Linux:
sudo pacman -S ncurses

# Ubuntu/Debian:
sudo apt-get install libncurses5-dev

# macOS:
# Usually pre-installed
```

### "Unicode characters not displaying"

```bash
# Set UTF-8 locale
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

### Performance lag with large directories

This is fixed in v1.0.2+. Make sure you're running the latest version:

```bash
gem update sergeant
sgt --version  # Should be 1.0.2 or higher
```

---

## Debugging

If sgt still doesn't work, run diagnostics:

```bash
# Check Ruby and gems
which ruby
ruby --version
gem list | grep -E "(curses|sergeant)"

# Check terminal
echo "TERM: $TERM"
echo "LANG: $LANG"

# Test curses
ruby -e "require 'curses'; Curses.init_screen; puts 'OK'; sleep 1; Curses.close_screen"

# Run with explicit ruby
ruby $(which sgt)

# Check for errors
sgt 2>&1 | cat
```

Please report issues at: https://github.com/biscoitinho/Sergeant/issues
