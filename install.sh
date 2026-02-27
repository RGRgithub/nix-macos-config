#!/usr/bin/env bash

set -e  # Exit on error

echo "======================================"
echo "Nix Configuration Installation Script"
echo "======================================"
echo ""

# Step 1: Install Nix using Determinate Systems installer
echo "[1/5] Installing Nix..."
if command -v nix &> /dev/null; then
    echo "Nix is already installed. Skipping installation."
else
    curl -fsSL https://install.determinate.systems/nix | sh -s -- install
    echo "Nix installed successfully!"
fi
echo ""

# Step 2: Check Full Disk Access for determinate-nixd
echo "[2/5] Checking Full Disk Access permissions..."

# Function to check if determinate-nixd has Full Disk Access
check_full_disk_access() {
    # Try to read a protected directory as a simple test
    if sudo -u nobody ls /Library/Application\ Support/ &>/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Check if determinate-nixd exists
if [ -f /usr/local/bin/determinate-nixd ] || [ -f /nix/var/nix/profiles/default/bin/determinate-nixd ]; then
    echo "Found determinate-nixd daemon."
    echo ""
    echo "⚠️  IMPORTANT: Full Disk Access Required"
    echo ""
    echo "The Determinate Nix installer requires Full Disk Access to function properly."
    echo "Without it, you may encounter 'operation not permitted' errors."
    echo ""
    echo "To grant Full Disk Access:"
    echo "  1. Open System Settings"
    echo "  2. Go to Privacy & Security → Full Disk Access"
    echo "  3. Toggle ON the switch for 'determinate-nixd'"
    echo "     (You may need to click the lock icon to make changes. 'determinate-nixd' is usually located at /usr/local/bin/determinate-nixd)"
    echo ""
    read -p "Press Enter after granting Full Disk Access, or press Ctrl+C to exit..."
    echo ""
else
    echo "determinate-nixd not found. Skipping Full Disk Access check."
fi
echo ""

# Step 3: Backup /etc files
echo "[2/5] Backing up /etc files..."

# Backup /etc/shells
if [ -f /etc/shells ] && [ ! -f /etc/shells.before-nix-darwin ]; then
    sudo mv /etc/shells /etc/shells.before-nix-darwin
    echo "/etc/shells backed up to /etc/shells.before-nix-darwin"
elif [ -f /etc/shells.before-nix-darwin ]; then
    echo "/etc/shells.before-nix-darwin already exists. Skipping backup."
else
    echo "/etc/shells does not exist. Skipping backup."
fi

# Backup /etc/zshenv
if [ -f /etc/zshenv ] && [ ! -f /etc/zshenv.before-nix-darwin ]; then
    sudo mv /etc/zshenv /etc/zshenv.before-nix-darwin
    echo "/etc/zshenv backed up to /etc/zshenv.before-nix-darwin"
elif [ -f /etc/zshenv.before-nix-darwin ]; then
    echo "/etc/zshenv.before-nix-darwin already exists. Skipping backup."
else
    echo "/etc/zshenv does not exist. Skipping backup."
fi
echo ""

# Step 4: Capture system information
echo "[4/5] Capturing system information..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_INFO_NIX="$SCRIPT_DIR/host-info.nix"
GIT_INFO_NIX="$SCRIPT_DIR/git-info.nix"

# Tell git to ignore local changes to these files (must be done before modifying)
git update-index --skip-worktree "$HOST_INFO_NIX" 2>/dev/null || true
git update-index --skip-worktree "$GIT_INFO_NIX" 2>/dev/null || true

# Create Nix version for use in flake.nix
cat > "$HOST_INFO_NIX" << EOF
# Auto-generated host information for Nix flake
# This file is created by install.sh
{
  hostname = "$(hostname -s)";
  username = "$USER";
  homedir = "$HOME";
  flakedir = "$SCRIPT_DIR";
}
EOF

echo "System information saved:"
echo "  Nix:   $HOST_INFO_NIX"
echo ""
echo "  HOSTNAME: $(hostname -s)"
echo "  USER: $USER"
echo "  HOME: $HOME"
echo ""

# Step 5: Run nix-darwin switch (system-level configuration)
echo "[5/6] Running nix-darwin switch..."
echo "This will configure system-level settings (requires sudo)"
echo ""

# Source the Nix environment if it exists
if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

sudo -H nix run nix-darwin -- switch --flake $SCRIPT_DIR

echo ""
echo "nix-darwin configuration applied successfully!"
echo ""

# Step 6: Run home-manager switch (user-level configuration)
echo "[6/6] Running home-manager switch..."
echo "This will configure user-level settings (no sudo required)"
echo ""

nix run home-manager/master -- switch --flake $SCRIPT_DIR

echo ""
echo "======================================"
echo "Installation Complete!"
echo "======================================"
echo ""
echo "Your system has been configured with:"
echo "  - nix-darwin (system-level)"
echo "  - home-manager (user-level)"
echo ""
echo "You may need to restart your terminal or run:"
echo "  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
echo ""
echo "To apply future configuration changes:"
echo ""
echo "  System changes (requires sudo, use rarely):"
echo "    sudo -H darwin-rebuild switch --flake $SCRIPT_DIR"
echo "    Or use the fish alias: dr:switch"
echo ""
echo "  User changes (no sudo, use for most updates):"
echo "    home-manager switch --flake $SCRIPT_DIR"
echo "    Or use the fish alias: hm:switch"
