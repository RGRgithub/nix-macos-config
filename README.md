# macOS Nix Configuration

A declarative macOS system configuration using [Nix](https://nixos.org/), [nix-darwin](https://github.com/LnL7/nix-darwin), [home-manager](https://github.com/nix-community/home-manager), and [Homebrew](https://brew.sh/) via [nix-homebrew](https://github.com/zhaofengli-wip/nix-homebrew).

## Features

- **Declarative System Configuration**: Manage your entire macOS system setup with code
- **Reproducible Environment**: Easily replicate your setup on multiple machines
- **Version Control**: Track all system changes in git
- **Personal Overrides**: Each team member can add their own packages and settings without touching shared config
- **Fish Shell**: Default shell with starship prompt, direnv integration, and zero-overhead `.env` loading; ZSH also available
- **Development Tools**: Includes Node.js, Corepack, GitHub CLI, Nix tooling, ngrok, direnv, and more
- **Docker-Compatible Container Runtime**: Podman with Docker CLI compatibility
- **GUI Applications**: Brave, Ghostty, Raycast, Slack, and more — properly integrated using mac-app-util
- **Homebrew Casks**: Microsoft Teams, Outlook, and personal casks — managed declaratively
- **VSCode**: Pre-configured with extensions, settings, and Nix IDE integration
- **Custom Fonts**: JetBrains Mono Nerd Font for editor and terminal

## Prerequisites

- macOS (Apple Silicon/ARM64)
- Git (comes pre-installed on macOS)
- Administrator access (sudo privileges)

## Installation

### 1. Clone this repository

```bash
git clone git@github.com:RGRgithub/nix-macos-config.git
cd nix-macos-setup
```

### 2. Run the installation script

```bash
./scripts/install.sh
```

The installer will:

1. Install Nix using the Determinate Systems installer
2. Prompt you to grant Full Disk Access to `determinate-nixd` (required)
3. Backup existing `/etc/shells` and `/etc/zshenv` files
4. Generate `variables/host-info.nix` from your system (hostname, username, home directory)
5. Create `variables/git-info.nix` with placeholder values for your git identity
6. Apply nix-darwin (system-level configuration, requires sudo)
7. Apply home-manager (user-level configuration)

### 3. Grant Full Disk Access

**IMPORTANT**: The Nix daemon requires Full Disk Access to function properly.

After running the installer, you'll be prompted to:

1. Open **System Settings**
2. Go to **Privacy & Security → Full Disk Access**
3. Toggle ON the switch for **determinate-nixd**
4. Press Enter in the terminal to continue

Without Full Disk Access, you may encounter "operation not permitted" errors when installing applications.

### 4. Set your git identity

Edit `variables/git-info.nix` with your name and email:

```nix
{
  name = "Your Name";
  email = "you@example.com";
}
```

Then apply the change:

```bash
hm:switch
```

## Repository Structure

```
.
├── flake.nix                              # Wires all modules and inputs together
├── flake.lock                             # Lock file for reproducible builds
├── configurations/
│   ├── darwin-configuration.nix           # Shared system-level config (dr:switch)
│   ├── user-darwin-configuration.nix      # Personal system-level overrides (dr:switch)
│   ├── home-configuration.nix             # Shared user-level config (hm:switch)
│   └── user-home-configuration.nix        # Personal user-level overrides (hm:switch)
├── variables/
│   ├── host-info.nix                      # Auto-generated — do not edit manually
│   └── git-info.nix                       # Your git name and email — edit after install
├── scripts/
│   ├── install.sh                         # Initial setup
│   └── uninstall.sh                       # Complete removal
└── README.md
```

> `variables/host-info.nix` and `variables/git-info.nix` are tracked in git with
> `skip-worktree`, so local changes never show as modified.

## Personal Customization

Two files are dedicated to per-person overrides and are hidden from git using `skip-worktree`:

### User-level (home-manager) — `configurations/user-home-configuration.nix`

Add personal packages, shell aliases, environment variables, and VSCode extensions:

```nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    neovim
    ripgrep
  ];

  programs.fish.shellAliases = {
    "my-alias" = "some-command";
  };

  programs.vscode.profiles.default.extensions = with pkgs.vscode-marketplace; [
    publisher.extension-name
  ];
}
```

Apply with: `hm:switch`

### System-level (nix-darwin) — `configurations/user-darwin-configuration.nix`

Add personal Homebrew casks:

```nix
{ ... }:
{
  homebrew.casks = [
    "some-app"
  ];
}
```

Apply with: `dr:switch`

## What's Included

### System Configuration (nix-darwin) — `configurations/darwin-configuration.nix`

- Fish set as default login shell (ZSH also available)
- Touch ID for sudo authentication
- JetBrains Mono Nerd Font
- System packages: Git, ZSH, OpenSSH
- Homebrew casks: Microsoft Teams, Microsoft Outlook
- System-level aliases:
  - `dr:switch` — Apply nix-darwin changes
  - `nix:update` — Update all flake inputs to their latest versions
  - `nix:install` — Re-run the install script
  - `nix:uninstall` — Run the uninstall script

### User Configuration (home-manager) — `configurations/home-configuration.nix`

**CLI tools:**

- btop, lazygit, gh (GitHub CLI)
- Node.js 24 + Corepack
- Podman + podman-compose (Docker-compatible)
- Python 3.15
- rbw (Bitwarden CLI)
- claude-code, gemini-cli
- nixfmt + nil (Nix formatter and LSP)
- ngrok (tunneling)
- direnv + nix-direnv (per-directory environment variables)
- sqlit-tui (SQLite TUI browser)

**GUI applications:**

- Bitwarden Desktop, Brave, Google Chrome
- Bruno (Git-native API client)
- Ghostty (terminal)
- Ice Bar (menu bar manager)
- Maccy (clipboard manager)
- Podman Desktop
- Raycast
- Shottr (screenshot tool)
- Slack, Spotify
- Warp Terminal

**VSCode:**

- Extensions: Claude Code, ESLint, Prettier, Nix IDE, Material Icons, npm/path IntelliSense, Mermaid Chart, Terraform, OXC
- Format on save with Prettier
- Nix language server (nil) with nixfmt
- JetBrains Mono Nerd Font (13pt, ligatures enabled)
- Fish integrated in terminal (custom profile with login shell flag)
- Automatic updates disabled (managed by Nix)

**Git:**

- Default branch name set to `main` globally

**Shell:**

- Fish as default login shell; ZSH also managed (with `compinit -u` to avoid startup hangs)
- Starship prompt with nerd-font-symbols preset
- `bass` plugin installed for running bash utilities from fish
- `~/.env` loaded at interactive startup using pure fish builtins (zero subprocesses)
- `env:reload` — Reload `~/.env` secrets into the current shell
- `hm:switch` — Apply home-manager changes
- `dr:switch` — Apply nix-darwin changes
- `docker` — Aliased to `podman` for Docker compatibility
- `EDITOR=code --wait`
- direnv hooks enabled (auto-loads `.envrc` on directory entry)

## Applying Changes

**User-level changes** (no sudo — use for most updates):

```bash
hm:switch
# or:
home-manager switch --flake .

# If you encounter file conflicts:
home-manager switch --flake . -b backup
```

**System-level changes** (requires sudo — use rarely):

```bash
dr:switch
# or:
sudo -H darwin-rebuild switch --flake .
```

**Update all flake inputs** to their latest versions:

```bash
nix:update
# or:
nix flake update
```

## Adding Packages

| What                    | Where                                                             | Command     |
| ----------------------- | ----------------------------------------------------------------- | ----------- |
| Personal packages       | `configurations/user-home-configuration.nix` → `home.packages`    | `hm:switch` |
| Shared team packages    | `configurations/home-configuration.nix` → `home.packages`         | `hm:switch` |
| Personal Homebrew casks | `configurations/user-darwin-configuration.nix` → `homebrew.casks` | `dr:switch` |
| Shared Homebrew casks   | `configurations/darwin-configuration.nix` → `homebrew.casks`      | `dr:switch` |
| System packages / fonts | `configurations/darwin-configuration.nix`                         | `dr:switch` |

## Uninstallation

```bash
./scripts/uninstall.sh
```

This will:

1. Switch your shell back to `/bin/zsh`
2. Uninstall nix-darwin
3. Restore backed up `/etc/shells` and `/etc/zshenv`
4. Uninstall Nix package manager

After uninstallation, restart your terminal.

## Troubleshooting

### "Operation not permitted" errors

Grant Full Disk Access to `determinate-nixd` in System Settings → Privacy & Security.

### Git permission errors after sudo commands

Running commands with `sudo` can create `.git` objects owned by root:

```bash
sudo chown -R $USER:staff .git
```

### Shell not changed after installation

Restart your terminal or source the Nix environment:

```bash
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### Changes not applying

Make sure you're using the right command for the right layer:

- GUI apps, fonts, Homebrew casks, system settings → `dr:switch` (nix-darwin)
- CLI tools, VSCode, shell aliases, user packages → `hm:switch` (home-manager)

### File conflicts in home-manager

```bash
home-manager switch --flake . -b backup
```

## Resources

- [Nix Package Search](https://search.nixos.org/packages)
- [Nix Darwin Options](https://daiderd.com/nix-darwin/manual/index.html)
- [Home Manager Options](https://nix-community.github.io/home-manager/options.xhtml)
- [Nix Pills](https://nixos.org/guides/nix-pills/) — Learn Nix in depth
