---
name: list-packages
description: Report all packages installed via this nix-macos-config, grouped by bucket with versions
allowed-tools: [Read, Bash, mcp__nixos__nix, mcp__homebrew__search]
---

Generate a full package report for this nix-macos-config. No arguments needed.

## Step 1 — Read the config files

Read these four files to extract all package lists:

- `configurations/darwin-configuration.nix` → `environment.systemPackages` and `homebrew.brews` and `homebrew.casks`
- `configurations/home-configuration.nix` → CLI tools section and GUI Applications section under `home.packages`
- `configurations/user-home-configuration.nix` → `home.packages`
- `configurations/user-darwin-configuration.nix` → `homebrew.casks`

## Step 2 — Get versions

### For nix packages (darwin system, home-manager CLI, home-manager GUI, personal home):

Run a single bash command to query all nix package versions at once. For each package name, evaluate:

```bash
nix eval --raw nixpkgs#<package>.version 2>/dev/null || echo "unknown"
```

Batch them efficiently — you can chain multiple evals in one bash call:

```bash
for pkg in btop claude-code nodejs_24 ...; do
  version=$(nix eval --raw "nixpkgs#${pkg}.version" 2>/dev/null || echo "unknown")
  echo "$pkg $version"
done
```

### For homebrew casks (shared and personal):

Use the homebrew MCP tool to look up cask info, or run:

```bash
brew info --cask --json=v2 claude microsoft-teams microsoft-outlook warp thebrowsercompany-dia \
  | jq -r '.[] | "\(.token): \(.version)"'
```

### For homebrew brews (if any):

```bash
brew list --versions
```

If the brews list is empty, skip this section.

## Step 3 — Format the report

Output the results as a clean markdown report with these sections in order. Only show a section if it has at least one package.

```
# Installed Packages

## Darwin System Packages
| Package  | Version |
|----------|---------|
| git      | x.y.z   |
...

## Homebrew Brews
| Package | Version |
|---------|---------|
...

## Homebrew Casks
| Cask               | Version |
|--------------------|---------|
| claude             | x.y.z   |
...

## Home Manager — CLI Tools
| Package       | Version |
|---------------|---------|
| btop          | x.y.z   |
...

## Home Manager — GUI Applications
| Package            | Version |
|--------------------|---------|
| bitwarden-desktop  | x.y.z   |
...

## Personal Packages
| Package | Source  | Version |
|---------|---------|---------|
| rbw     | nix     | x.y.z   |
| thebrowsercompany-dia | homebrew cask | x.y.z |
...
```

Keep the table rows sorted alphabetically within each section, matching the order in the config files.
