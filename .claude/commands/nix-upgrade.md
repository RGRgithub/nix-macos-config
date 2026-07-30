---
name: nix-upgrade
description: Bump all flake inputs, apply them with the install script, fix any breakage, then open a PR
allowed-tools: [Read, Edit, Write, Bash, Glob, Grep, WebFetch, WebSearch, mcp__nixos__nix, mcp__homebrew__info, mcp__homebrew__search]
---

Run the full flake-upgrade cycle for this repo: update inputs → apply them → fix what breaks → open a PR.
No arguments needed.

This runs on **this Mac** — it needs `sudo` and applies real system state. Do not try to
shortcut it into a build-only check; the point is that the upgrade is proven to switch cleanly
before the PR goes up.

## Step 0 — Preflight

Work from the repo root (the `flakedir` in `variables/host-info.nix`).

```sh
git status --porcelain
git rev-parse --abbrev-ref HEAD
```

- If the working tree is dirty, **stop and show the user what's uncommitted.** Ask whether to
  include those changes in this upgrade, stash them, or abort. Never stash silently.
  Note: `variables/host-info.nix`, `variables/git-info.nix`,
  `configurations/user-darwin-configuration.nix`, and `configurations/user-home-configuration.nix`
  are marked `--skip-worktree` by `install.sh`, so they won't appear here even when modified —
  that's expected, and they must never be committed.
- If not on `main`, ask before proceeding.
- Then: `git checkout main && git pull --ff-only`.

## Step 1 — Branch first

Branch **before** touching `flake.lock`, so both the lock bump and any fixes land together on the
branch and `main` stays clean if the upgrade has to be abandoned.

```sh
git checkout -b chore/flake-update-$(date +%Y-%m-%d)
```

If that branch already exists (a second run the same day), append `-2`, `-3`, etc.

## Step 2 — nix:update

```sh
nix flake update
```

**Capture the full output.** It prints one `• Updated input '<name>': <old> → <new>` line per input —
that list is the raw material for the commit message and PR body. Save it; don't re-derive it later
from the lockfile diff.

If nothing was updated, say so and stop — delete the branch (`git checkout main && git branch -d …`)
rather than opening an empty PR.

## Step 3 — Build gate (no sudo)

Before spending a `sudo` switch on it, prove both configs evaluate and build:

```sh
darwin-rebuild build --flake .
home-manager build --flake .
```

This catches eval errors, removed options, and broken derivations quickly and without touching
system state. If either fails, go straight to Step 5 — don't run the install script on a config
that can't build.

Clean up the `result` / `result-*` symlinks these leave behind before committing.

## Step 4 — nix:install

```sh
./scripts/install.sh
```

This runs unattended, but **it needs one Touch ID tap from the user.** Tell them to expect it
before you start the command, so they aren't staring at a stalled tool call:

> Running the switch now — **tap Touch ID** when the prompt appears.

Why it works: the script's `sudo -H nix run nix-darwin -- switch` authenticates through
`pam_tid.so`, which `security.pam.services.sudo_local.touchIdAuth` puts first in the sudo PAM
chain as `sufficient`. Touch ID is a system modal, so it needs no TTY and works fine from a tool
call. The script's Full Disk Access prompt is TTY-guarded and self-skips when there's no
terminal.

Expect this to be slow — it's a full system switch plus a `brew bundle`. Give it a long timeout
(10+ minutes) rather than assuming it hung.

If it still fails on sudo or on a prompt, **don't patch `install.sh` to get around it** — that
script is shared by the whole team and a workaround there is how you break someone's fresh
install. Ask the user to run it instead, and read their output:

> Run `! ./scripts/install.sh` — I need the output to continue.

Treat "the user ran it and it succeeded" exactly the same as having run it yourself.

## Step 5 — Fix what broke

Only if Step 3 or Step 4 failed.

**Diagnose the actual mechanism before changing anything.** Read the real error — the failing
derivation's log (`nix log <drv>`), the specific option that no longer exists, the phase that
failed. A plausible-sounding patch that makes the error message go away is worse than no patch.

Then pick the smallest fix that fits the existing conventions in this repo:

| Failure | Usual fix |
|---|---|
| A nix-darwin / home-manager option was renamed or removed | Update the option in the relevant `configurations/*.nix` |
| An upstream package build is broken on darwin | Patch it via an overlay in `flake.nix` (see the vscode/ripgrep precedent in git history), or pin that one input back |
| A Homebrew cask/tap changed | Fix `homebrew.casks` / `nix-homebrew.taps` in `darwin-configuration.nix` — and remember managed taps must also be listed in `homebrew.taps` |
| A package was renamed or dropped from nixpkgs | Verify the new attribute name with `nix search nixpkgs <name>` before editing — don't guess |
| The regression is squarely upstream and not worth working around | Pin that single input back to its previous rev in `flake.lock` and note it in the PR |

After each fix, re-run the failed step. **Cap this at 3 attempts.** If it's still broken after
three, stop and report: what failed, what you tried, what the evidence points to, and what you'd
do next. Leave the branch in place for the user. Don't keep grinding.

Run `nixfmt` on any `.nix` file you edited.

## Step 6 — Commit

Stage deliberately — `flake.lock` plus only the files you actually edited. Never `git add -A`
(it will sweep up `result` symlinks and `.DS_Store`).

Commit message: conventional-commits, and the body should say what moved and why any fix was
needed.

```
chore: bump flake inputs

Updated: nixpkgs, home-manager, nix-vscode-extensions, …
(one line per input, with the notable version jumps called out —
e.g. "nixpkgs: nixos-25.11 → nixos-26.05")

<If fixes were needed, a paragraph per fix: the failure, the cause,
and why this fix rather than an alternative.>

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
```

## Step 7 — PR

```sh
git push -u origin HEAD
gh pr create --base main --title "chore: bump flake inputs" --body "…"
```

Body should contain:

- **Inputs updated** — a table of input → old rev/date → new rev/date, from the Step 2 output.
- **Verification** — state plainly what actually ran and passed: `darwin-rebuild build`,
  `home-manager build`, `./scripts/install.sh`. If the user ran the install script rather than
  you, say so. If a step was skipped, say that too. Don't claim a clean switch you didn't see.
- **Fixes** — any config changes made to get the upgrade through, with the reasoning.
- **Risks** — anything the user should re-check by hand: a major nixpkgs channel jump, a pinned-back
  input, a cask that changed source, anything touching permissions or activation scripts.
- Footer: `🤖 Generated with [Claude Code](https://claude.com/claude-code)`

Finish by printing the PR URL.
