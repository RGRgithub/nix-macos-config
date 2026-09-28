# macOS Nix Configuration

A declarative macOS system configuration using [Nix](https://nixos.org/), [nix-darwin](https://github.com/nix-darwin/nix-darwin), [home-manager](https://github.com/nix-community/home-manager), and [Homebrew](https://brew.sh/) via [nix-homebrew](https://github.com/zhaofengli-wip/nix-homebrew).

## Features

- **Declarative System Configuration**: Manage your entire macOS system setup with code
- **Reproducible Environment**: Every flake input, including the Homebrew taps, is pinned in `flake.lock`
- **Personal Overrides**: Each team member can add their own packages and settings without touching shared config
- **Fish Shell**: Default shell with starship prompt and direnv integration; ZSH also available
- **Development Tools**: Node.js, Python, AWS/GCP CLIs, Terraform, GitHub CLI, Nix tooling, and more
- **Docker-Compatible Container Runtime**: Podman with Docker CLI compatibility
- **GUI Applications**: Homebrew casks plus a few Nix-packaged apps, integrated using mac-app-util
- **VSCode**: Pre-configured with extensions, settings, and Nix IDE integration
- **Self-cleaning store**: every switch keeps only the current generation and sweeps unused store paths

## Prerequisites

- macOS (Apple Silicon/ARM64)
- Git (comes pre-installed on macOS)
- Administrator access (sudo privileges)

## Installation

### 1. Clone this repository

```bash
git clone git@github.com:RGRgithub/nix-macos-config.git
cd nix-macos-config
```

### 2. Run the installation script

```bash
./scripts/install.sh
```

The installer will:

1. Install Nix using the Determinate Systems installer (or check it's up to date)
2. Prompt you to grant Full Disk Access to `determinate-nixd` (required)
3. Backup existing `/etc/shells` and `/etc/zshenv` files
4. Generate `variables/host-info.nix` from your system (hostname, username, home directory)
5. Mark `variables/git-info.nix` (placeholders for your git identity) and the personal override files as `skip-worktree`
6. Apply nix-darwin (system-level configuration, requires sudo)
7. Apply home-manager (user-level configuration)

Re-running it later (`nix:install`) is safe and applies both layers. Note that each run also
upgrades Nix if a newer Determinate release exists, and uses the latest nix-darwin and
home-manager CLIs rather than the pinned ones.

### 3. Grant Full Disk Access

**IMPORTANT**: The Nix daemon requires Full Disk Access to function properly.

The installer pauses (when run in a terminal) while you:

1. Open **System Settings**
2. Go to **Privacy & Security → Full Disk Access**
3. On a fresh machine `determinate-nixd` isn't listed yet: click **+**, press **Cmd+Shift+G**,
   paste `/usr/local/bin/determinate-nixd`, and click **Open**. If it's already listed, toggle it ON.
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
│   ├── git-info.nix                       # Your git name and email — edit after install
│   └── direnv-whitelist.nix               # Repos whose .envrc direnv auto-allows
├── scripts/
│   ├── install.sh                         # Setup / re-apply everything
│   └── uninstall.sh                       # Complete removal
├── .claude/commands/                      # Claude Code commands (/nix-upgrade, /list-packages)
├── AGENTS.md                              # Guidance for AI coding agents
└── README.md
```

> `variables/host-info.nix`, `variables/git-info.nix` and the two `user-*-configuration.nix`
> files are tracked in git with `skip-worktree`, so local changes never show as modified.

## Personal Customization

Two files are dedicated to per-person overrides:

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
- Homebrew brews: moon, podman, podman-compose, proto
- Homebrew casks: Bitwarden, Brave, Bruno, Claude, Claude Code, Ghostty, Google Chrome,
  Ice (menu bar), Loop, Podman Desktop, Raycast, ShotX, Spotify, Warp, Zoom
- Homebrew is fully declarative: taps are pinned flake inputs, and anything not listed is
  uninstalled on switch

### User Configuration (home-manager) — `configurations/home-configuration.nix`

**CLI tools:**

- awscli2, google-cloud-sdk
- btop, jq, lazygit, lazydocker
- gh (GitHub CLI)
- Node.js 24 + Corepack, Python 3.14
- Terraform, Terragrunt
- ngrok (tunneling)
- nixfmt + nil (Nix formatter and LSP), mcp-nixos (Nix MCP server)
- direnv + nix-direnv (per-directory environments)

**GUI applications:** Maccy (clipboard manager), Shottr (screenshots), Slack

**VSCode:**

- Extensions: Claude Code, ESLint, Prettier, Nix IDE, direnv, Python, YAML, Terraform, OXC,
  Mermaid Chart, moon console, Git Graph, Material Icons, npm/path IntelliSense
- Format on save with Prettier
- Nix language server (nil) with nixfmt
- JetBrains Mono Nerd Font (13pt, ligatures enabled)
- Fish integrated in terminal (custom profile with login shell flag)
- Automatic updates disabled (managed by Nix)

**Git:**

- Name, email and default branch `main`, applied once `variables/git-info.nix` has your name and email

**Shell:**

- Starship prompt with nerd-font-symbols preset
- `bass` plugin installed for running bash utilities from fish
- `~/.env` (your secrets, never committed) loaded via direnv anywhere under `$HOME` without its own `.envrc`
- `EDITOR=code --wait`
- Aliases:
  - `hm:switch` — Apply home-manager changes
  - `dr:switch` — Apply nix-darwin changes
  - `nix:install` — Re-run the install script (applies both layers)
  - `nix:update` — Update all flake inputs to their latest versions
  - `nix:uninstall` — Run the uninstall script
  - `env:reload` — Reload `~/.env` into the current shell
  - `docker` — Aliased to `podman`

## Applying Changes

**User-level changes** (no sudo — use for most updates):

```bash
hm:switch
```

**System-level changes** (requires sudo — use rarely):

```bash
dr:switch
```

**Both layers at once:**

```bash
nix:install
```

**Update all flake inputs** to their latest versions:

```bash
nix:update
```

In Claude Code, `/nix-upgrade` runs the full cycle: update, build, switch, fix breakage, open a PR.

> Every switch keeps only the current generation, so `--rollback` has nothing to roll back to.
> To undo a bad change, revert it in git and switch again.

## Adding Packages

| What                    | Where                                                             | Command     |
| ----------------------- | ----------------------------------------------------------------- | ----------- |
| Personal packages       | `configurations/user-home-configuration.nix` → `home.packages`    | `hm:switch` |
| Shared team packages    | `configurations/home-configuration.nix` → `home.packages`         | `hm:switch` |
| Personal Homebrew casks | `configurations/user-darwin-configuration.nix` → `homebrew.casks` | `dr:switch` |
| Shared Homebrew casks   | `configurations/darwin-configuration.nix` → `homebrew.casks`      | `dr:switch` |
| System packages / fonts | `configurations/darwin-configuration.nix`                         | `dr:switch` |

A cask from a third-party tap also needs that tap added as a flake input and under `nix-homebrew.taps`.

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

- Homebrew casks, fonts, system settings → `dr:switch` (nix-darwin)
- Nix packages (CLI tools and the Nix GUI apps), VSCode, shell aliases → `hm:switch` (home-manager)

### File conflicts in home-manager

```bash
home-manager switch --flake . -b backup
```

## Resources

- [Nix Package Search](https://search.nixos.org/packages)
- [Nix Darwin Options](https://nix-darwin.github.io/nix-darwin/manual/)
- [Home Manager Options](https://nix-community.github.io/home-manager/options.xhtml)
- [Nix Pills](https://nixos.org/guides/nix-pills/) — Learn Nix in depth
