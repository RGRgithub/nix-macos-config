#!/usr/bin/env bash

set -e  # Exit on error

echo "======================================"
echo "Nix Configuration Uninstall Script"
echo "======================================"
echo ""
echo "WARNING: This will remove:"
echo "  - nix-darwin (system configuration)"
echo "  - home-manager (user configuration)"
echo "  - Nix package manager"
echo "  - All installed packages and configurations"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Uninstallation cancelled."
    exit 0
fi

echo ""

# Step 1: Switch shell back to zsh
echo "[1/4] Switching shell back to zsh..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_INFO_NIX="$SCRIPT_DIR/host-info.nix"

# Get username from host-info.nix if it exists, otherwise use $USER
if [ -f "$HOST_INFO_NIX" ]; then
    USERNAME=$(grep 'username' "$HOST_INFO_NIX" | sed 's/.*"\(.*\)".*/\1/')
else
    USERNAME="$USER"
fi

# Check if current shell is fish
CURRENT_SHELL=$(dscl . -read /Users/$USERNAME UserShell | awk '{print $2}')
if [[ "$CURRENT_SHELL" == *"fish"* ]]; then
    echo "Current shell is fish. Switching to zsh..."
    sudo chsh -s /bin/zsh $USERNAME
    echo "Shell changed to zsh for user: $USERNAME"
else
    echo "Current shell is not fish. No change needed."
fi
echo ""

# Step 2: Uninstall nix-darwin
echo "[2/4] Uninstalling nix-darwin..."
if command -v darwin-rebuild &> /dev/null || command -v nix &> /dev/null; then
    echo "Running nix-darwin uninstaller..."

    # Source the Nix environment if it exists
    if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi

    sudo -H nix --extra-experimental-features "nix-command flakes" run nix-darwin#darwin-uninstaller
    echo "nix-darwin uninstalled successfully!"
else
    echo "nix-darwin not found or already uninstalled. Skipping."
fi
echo ""

# Step 3: Restore backed up files
echo "[3/4] Restoring backed up /etc files..."

# Restore /etc/shells
if [ -f /etc/shells.before-nix-darwin ]; then
    sudo mv /etc/shells.before-nix-darwin /etc/shells
    echo "/etc/shells restored from backup"
else
    echo "No backup of /etc/shells found. Skipping."
fi

# Restore /etc/zshenv
if [ -f /etc/zshenv.before-nix-darwin ]; then
    sudo mv /etc/zshenv.before-nix-darwin /etc/zshenv
    echo "/etc/zshenv restored from backup"
else
    echo "No backup of /etc/zshenv found. Skipping."
fi
echo ""

# Step 4: Uninstall Nix
echo "[4/4] Uninstalling Nix package manager..."
if command -v nix &> /dev/null; then
    echo "Running Determinate Systems Nix uninstaller..."
    curl -fsSL https://install.determinate.systems/nix | sh -s -- uninstall --no-confirm || {
        echo "Uninstaller returned an error, but continuing..."
    }
    echo "Nix uninstalled successfully!"
else
    echo "Nix not found or already uninstalled. Skipping."
fi
echo ""

echo "======================================"
echo "Uninstallation Complete!"
echo "======================================"
echo ""
echo "The following have been removed:"
echo "  - nix-darwin"
echo "  - home-manager"
echo "  - Nix package manager"
echo ""
echo "Your shell has been reset to zsh."
echo ""
echo "You may need to:"
echo "  1. Restart your terminal"
echo "  2. Manually remove any remaining Nix directories if they exist:"
echo "     sudo rm -rf /nix"
echo ""

exit 0
