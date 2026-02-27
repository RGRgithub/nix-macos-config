# macOS Nix Configuration

A declarative macOS system configuration using [Nix](https://nixos.org/), [nix-darwin](https://github.com/LnL7/nix-darwin), and [home-manager](https://github.com/nix-community/home-manager).

## Features

- **Declarative System Configuration**: Manage your entire macOS system setup with code
- **Reproducible Environment**: Easily replicate your setup on multiple machines
- **Version Control**: Track all system changes in git
- **Easy Updates**: Simple commands to apply configuration changes
- **Fish Shell**: Configured with useful aliases
- **Development Tools**: Includes Node.js, Corepack, GitHub CLI, Nix tooling, and more
- **Docker-Compatible Container Runtime**: Podman with automatic machine startup and Docker CLI compatibility
- **GUI Applications**: Bitwarden, Brave, Podman Desktop, Raycast, and more - properly integrated using mac-app-util
- **VSCode Extensions**: Pre-configured with essential extensions
- **Custom Fonts**: JetBrains Mono Nerd Font for enhanced coding experience

## Prerequisites

- macOS (Apple Silicon/ARM64)
- Git (comes pre-installed on macOS)
- Administrator access (sudo privileges)

## Installation

### 1. Clone this repository

```bash
git clone git@github.com:sam-com/nix-macos-setup.git
cd nix-macos-setup
```

### 2. Run the installation script

```bash
./install.sh
```

The installer will:

1. Install Nix using the Determinate Systems installer
2. Prompt you to grant Full Disk Access to `determinate-nixd` (required)
3. Backup existing `/etc/shells` and `/etc/zshenv` files
4. Capture your system information (hostname, username, home directory)
5. Install and configure nix-darwin (system-level configuration)
6. Install and configure home-manager (user-level configuration)

### 3. Grant Full Disk Access

**IMPORTANT**: The Nix daemon requires Full Disk Access to function properly.

After running the installer, you'll be prompted to:

1. Open **System Settings**
2. Go to **Privacy & Security → Full Disk Access**
3. Toggle ON the switch for **determinate-nixd**
4. You may need to click the lock icon to make changes
5. Press Enter in the terminal to continue

Without Full Disk Access, you may encounter "operation not permitted" errors when installing applications.

## What's Included

### System Configuration (nix-darwin)

- Fish shell set as default shell
- Touch ID for sudo authentication
- JetBrains Mono Nerd Font (used in VSCode)
- System-level packages:
  - Git, Fish
  - Bitwarden Desktop (password manager)
  - Brave Browser
  - btop (system monitor)
  - Ice Bar (menu bar management)
  - Maccy (clipboard manager)
  - Podman Desktop
  - Raycast (productivity and launcher app)
  - Shottr (screenshot tool)
- System-level aliases:
  - `dr:switch` - Apply darwin-rebuild changes

### User Configuration (home-manager)

**Development Tools:**

- nixfmt (Nix formatter)
- nil (Nix LSP)
- Node.js 24
- Corepack 24 (Node.js package manager manager)
- GitHub CLI (gh) for GitHub integration
- Podman with Docker compatibility
- podman-compose (Docker Compose for Podman)

**GUI Applications:**

- Visual Studio Code (with extensions)

**VSCode Extensions:**

- ESLint
- GitLens
- Prettier
- Nix IDE
- Mermaid Chart

**VSCode Settings:**

- Claude Code in panel location
- Format on save enabled with Prettier as default formatter
- Nix language server (nil) integration with nixfmt formatter
- JetBrains Mono Nerd Font for editor and terminal (13pt with ligatures)
- Fish shell integrated in terminal
- Native tabs and window state preservation
- Automatic updates disabled (managed by Nix)

**Shell Configuration:**

- Fish shell aliases:
  - `hm:switch` - Apply home-manager changes
  - `docker` - Aliased to `podman` for Docker compatibility
- Environment variables:
  - `EDITOR=code --wait` - VSCode as default editor
  - `PODMAN_COMPOSE_WARNING_LOGS=false` - Suppress Podman Compose warnings

## Usage

### Updating Dependencies

To update all flake inputs (nixpkgs, home-manager, nix-darwin, etc.) to their latest versions:

```bash
nix flake update
```

This updates the [flake.lock](flake.lock) file with the latest versions. After updating, apply the changes using the commands below.

### Applying Configuration Changes

After modifying [flake.nix](flake.nix), apply changes using:

**System-level changes** (requires sudo, use rarely):

```bash
sudo -H darwin-rebuild switch --flake .
# Or use the Fish alias:
dr:switch
```

**User-level changes** (no sudo, use for most updates):

```bash
home-manager switch --flake .
# Or use the Fish alias:
hm:switch

# If you encounter file conflicts, use the backup flag:
home-manager switch --flake . -b backup
# Or:
hm:switch -b backup
```

### Adding New Packages

Edit [flake.nix](flake.nix) and add packages to the `home.packages` list:

```nix
home.packages = with pkgs; [
  # Add your packages here
  ripgrep
  fzf
];
```

Then run `home-manager switch --flake .` to apply changes.

### Using Podman (Docker Alternative)

Podman is configured with full Docker compatibility:

**Docker Commands Work Automatically:**

```bash
docker run -it alpine sh
docker ps
docker build -t myapp .
docker compose up
```

The `docker` command is aliased to `podman`, so all Docker commands work seamlessly.

**Podman Machine:**

- A Podman machine named `podman-machine-default` is automatically created and configured
- The machine auto-starts on login (managed by launchd)
- No manual `podman machine init` or `podman machine start` needed

**Compose Support:**

- Both `podman compose` and `podman-compose` commands are available
- Docker Compose files work without modification
- Warning messages are suppressed via `PODMAN_COMPOSE_WARNING_LOGS=false`

**Managing Podman:**

```bash
# Check machine status
podman machine list

# View running containers
podman ps

# Stop/start machine manually if needed
podman machine stop podman-machine-default
podman machine start podman-machine-default
```

### Modifying VSCode Configuration

Edit the `programs.vscode` section in [flake.nix](flake.nix):

```nix
programs.vscode = {
  enable = true;
  package = pkgs.vscode;
  profiles.default.extensions = with pkgs.vscode-marketplace; [
    # Add extensions here
  ];
  profiles.default.userSettings = {
    # Add settings here
  };
};
```

## File Structure

```
.
├── flake.nix           # Main configuration file
├── flake.lock          # Lock file for reproducible builds
├── host-info.nix       # Auto-generated host-specific information (git-ignored)
├── install.sh          # Installation script
├── uninstall.sh        # Uninstallation script
└── README.md           # This file
```

## Uninstallation

To completely remove Nix and all configurations:

```bash
./uninstall.sh
```

This will:

1. Switch your shell back to zsh
2. Uninstall nix-darwin
3. Restore backed up `/etc` files
4. Uninstall Nix package manager

After uninstallation, restart your terminal.

## Troubleshooting

### "Operation not permitted" errors

**Solution**: Grant Full Disk Access to `determinate-nixd` in System Settings (see installation step 3).

### Git permissions errors ("insufficient permission for adding an object")

**Problem**: When running `nix flake update` or other Git operations, you see errors like:

```
error: insufficient permission for adding an object to repository database .git/objects
fatal: cannot create an empty blob in the object database
```

**Cause**: This typically happens when Git operations were previously run with `sudo`, creating files and directories owned by `root` in your `.git` directory.

**Solution**: Fix the ownership of the `.git` directory:

```bash
sudo chown -R $USER:staff .git
```

Replace `$USER` with your username if the variable isn't set. After running this command, Git operations should work normally.

### Shell not changed after installation

**Solution**: Restart your terminal or run:

```bash
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### Changes not applying

**Solution**: Make sure you're running the correct command:

- For system changes: `sudo -H darwin-rebuild switch --flake .`
- For user changes: `home-manager switch --flake .`

## Customization

### Changing the Default Shell

Edit the `darwinConfiguration` section in [flake.nix](flake.nix):

```nix
users.users.${hostInfo.username} = {
  shell = pkgs.zsh;  # Change to your preferred shell
};
```

### Adding System Packages

Edit the `darwinConfiguration` section in [flake.nix](flake.nix):

```nix
environment.systemPackages = [
  pkgs.git
  pkgs.fish
  # Add more packages here
];
```

## Resources

- [Nix Package Search](https://search.nixos.org/packages)
- [Nix Darwin Manual](https://daiderd.com/nix-darwin/manual/index.html)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Pills](https://nixos.org/guides/nix-pills/) - Learn Nix in depth

## License

This configuration is provided as-is for personal use.
