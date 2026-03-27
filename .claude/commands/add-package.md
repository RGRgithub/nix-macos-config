---
name: add-package
description: Search for and add a nix or homebrew package to the right configuration file
argument-hint: <package-name-or-description> [--personal]
allowed-tools: [Read, Edit, Glob, Grep, Bash, mcp__nixos__nix, mcp__homebrew__search]
---

Add a package to this nix-macos-config. Arguments: `$ARGUMENTS`

Parse the arguments: extract the package name/description, and check if `--personal` was passed.

## Step 1 — Find the nix package

Search nixpkgs using the `mcp__nixos__nix` tool:
- `action: search`, `source: nixos`, `type: packages`, `query: <name>`

Identify the best match by name and description. If multiple packages share a similar name (ambiguous results), **always** verify the exact attribute name by running:

```bash
nix search nixpkgs <name>
```

The output shows the full attribute path (e.g., `legacyPackages.x86_64-darwin.zoom-us`) — use the last segment as the package attribute name.

## Step 2 — Determine where to place it

Use this decision table:

| Package type     | Shared (default)                                           | Personal (`--personal`)          |
|------------------|------------------------------------------------------------|----------------------------------|
| CLI / TUI tool   | `configurations/home-configuration.nix` — CLI tools section      | `configurations/user-home-configuration.nix` |
| GUI application  | `configurations/home-configuration.nix` — GUI Applications section | `configurations/user-home-configuration.nix` |
| Homebrew cask    | `configurations/darwin-configuration.nix` — homebrew.casks list   | `configurations/user-darwin-configuration.nix` — homebrew.casks list |

If it's not obvious whether a package is CLI or GUI, check the package description from the search results. GUI apps are typically desktop applications; CLI/TUI tools run in the terminal.

## Step 3 — Insert alphabetically

Read the target file. Find the correct section. Insert the package attribute name in alphabetical order among the existing entries, preserving the surrounding formatting and indentation.

## Step 4 — Fallback: Homebrew

If no suitable nix package exists, search for a Homebrew cask using the `mcp__homebrew__search` tool (or equivalent homebrew MCP tool available in context). Search for the cask by name.

If a cask is found, add it to the appropriate casks list (see Step 2 table) in alphabetical order.

If neither nix nor homebrew has a match, inform the user.

## Notes

- Always confirm the package name and target file with the user before editing if there is any ambiguity.
- Do not add the same package to both shared and user files.
- Preserve the existing comment headers (`# CLI tools`, `# GUI Applications`) in home-configuration.nix.
