# AGENTS.md

This file provides guidance to AI coding agents working in this repository.

## Overview

This is a declarative macOS system configuration using Nix flakes with two layers:
- **nix-darwin**: System-level configuration (requires sudo)
- **home-manager**: User-level configuration (most changes)

The configuration uses `variables/host-info.nix` (auto-generated, git-ignored) to provide system-specific values (hostname, username, homedir, flakedir) that are interpolated throughout the flake.

## Common Commands

### Applying Configuration Changes

**User-level changes** (preferred for most updates):
```sh
home-manager switch --flake .
# Or with alias:
hm:switch

# If file conflicts occur:
home-manager switch --flake . -b backup
```

**System-level changes** (rarely needed):
```sh
sudo -H darwin-rebuild switch --flake .
# Or with alias:
dr:switch
```

### Updating Dependencies

Update all flake inputs to latest versions:
```sh
nix flake update
```

### Installation & Uninstallation

```sh
./scripts/install.sh      # Initial setup
./scripts/uninstall.sh    # Complete removal
```

### Validation & Testing

**Validate flake syntax:**
```sh
nix flake check
```

**Build without switching (dry-run):**
```sh
# For user config:
home-manager build --flake .

# For system config:
darwin-rebuild build --flake .
```

**Check what would change:**
```sh
# For user config:
nix build .#homeConfigurations.(hostname).activationPackage --dry-run

# For system config:
nix build .#darwinConfigurations.(hostname).system --dry-run
```

### Formatting

Format all Nix files:
```sh
nixfmt **/*.nix
```

## Architecture

### Two-Layer Configuration System

1. **nix-darwin** (`configurations/darwin-configuration.nix`):
   - System packages, fonts, shells
   - Homebrew brews, casks and taps (via nix-homebrew, taps pinned as flake inputs)
   - Touch ID for sudo
   - Activation scripts for system setup

2. **home-manager** (`configurations/home-configuration.nix`):
   - User packages (development tools, CLIs)
   - VSCode with extensions and settings
   - Fish shell aliases and environment variables
   - Application trampolines for persistent permissions (via mac-app-util)

3. **personal overrides** (`configurations/user-darwin-configuration.nix`, `configurations/user-home-configuration.nix`):
   - Per-team-member packages, casks, aliases, and settings on top of the shared config
   - Marked `--skip-worktree` by `install.sh`, so local edits never get committed

### Key Dependencies

- **mac-app-util**: Creates application trampolines to maintain macOS permissions and proper app integration for GUI applications
- **nix-vscode-extensions**: Provides access to VSCode marketplace extensions
- **nixpkgs**: Package repository (using unstable channel)

### Variables Pattern

`scripts/install.sh` manages two files in `variables/` and marks them `--skip-worktree`, so local values never get committed:

- `variables/host-info.nix` — auto-generated from system values (hostname, username, homedir, flakedir). Never edit manually.
- `variables/git-info.nix` — created on first install with commented-out placeholders. Edit with your name and email, then run `hm:switch`.

`variables/direnv-whitelist.nix` is shared config listing the repos whose `.envrc` direnv auto-allows.

### Flake Structure

The flake exports two configurations:
- `darwinConfigurations.${hostInfo.hostname}`: System configuration
- `homeConfigurations.${hostInfo.username}`: User configuration

Both reference the same `hostInfo` to ensure consistency.

## Development Workflow

### Adding Packages

**Personal packages** (your own additions):
Add to `home.packages` in `configurations/user-home-configuration.nix` (or `homebrew.casks` in `configurations/user-darwin-configuration.nix`), then apply.

**Shared user packages** (for the whole team):
Add to `home.packages` in `configurations/home-configuration.nix`, then run `hm:switch`.

**System packages, fonts and GUI apps**:
Add to `environment.systemPackages`, `fonts.packages` or `homebrew.casks` in `configurations/darwin-configuration.nix`, then run `dr:switch`.

### Adding VSCode Extensions

Extensions come from the `nix-vscode-extensions` overlay. Add to `programs.vscode.profiles.default.extensions`:
```nix
profiles.default.extensions = with pkgs.vscode-marketplace; [
  publisher.extension-name
];
```

Search for extensions at: https://search.nixos.org/packages (filter by "vscode-extensions")

### Shell Aliases & Environment

**Shared user aliases**: Edit `programs.fish.shellAliases` in `configurations/home-configuration.nix`
**Personal aliases**: Edit `programs.fish.shellAliases` in `configurations/user-home-configuration.nix`
**Environment variables**: Edit `home.sessionVariables` in `configurations/home-configuration.nix`

### Podman Configuration

`podman`, `podman-compose` and `podman-desktop` are installed through Homebrew (`homebrew.brews` / `homebrew.casks` in `darwin-configuration.nix`). The `docker` fish alias points at `podman`.

## Important Notes

### Git Worktree Management

If encountering git permission errors after running commands with sudo:
```sh
sudo chown -R $USER:staff .git
```

### Full Disk Access Requirement

The `determinate-nixd` daemon requires Full Disk Access in System Settings → Privacy & Security. Without this, "operation not permitted" errors will occur when installing applications.

### Activation Scripts

System activation (`configurations/darwin-configuration.nix`):
- Sets fish as the login shell (only runs `chsh` when it differs)
- Removes unmanaged Homebrew `Taps` dirs before nix-homebrew setup
- Keeps only the current system generation and sweeps store garbage

Home activation (`configurations/home-configuration.nix`):
- Sets up `~/.envrc` / `~/.env` for direnv
- Keeps only the current user-profile generation, sweeps and optimises the store
- Creates app trampolines via mac-app-util

nix-darwin only runs a fixed list of activation script names; a custom `system.activationScripts.<name>` builds but never runs. Add system activation work to `postActivation` or an existing hook.

### Font Configuration

JetBrains Mono Nerd Font is installed at system level but configured in VSCode and terminal settings in home-manager. Both layers must be applied for fonts to work properly in VSCode.

## Troubleshooting

### Changes Not Applying

Ensure you're using the correct layer:
- GUI apps, fonts, system settings → `dr:switch` (nix-darwin)
- Development tools, VSCode, user configs → `hm:switch` (home-manager)

### Shell Not Changing

Restart terminal or source the Nix environment:
```sh
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### File Conflicts in home-manager

Use the backup flag:
```sh
home-manager switch --flake . -b backup
```

## Resources

- Nix Package Search: https://search.nixos.org/packages
- Nix Darwin Options: https://nix-darwin.github.io/nix-darwin/manual/
- Home Manager Options: https://nix-community.github.io/home-manager/options.xhtml
