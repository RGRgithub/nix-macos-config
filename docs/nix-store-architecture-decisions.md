# Nix store cleanup — architecture decisions

Goal: keep `/nix` from bloating on every team Mac, automatically, with nothing for
the owner to remember.

## Decision 1 — Sweep the store once, at the end of the home-manager switch (2026-11-20)

**Decision.** The store sweep (`nix store gc`) runs only in home-manager activation
(`home.activation.sweepStore`). The sweep that used to run at the end of nix-darwin
activation is removed. Generation pruning is unchanged: both layers still keep only
the current generation.

**Reasoning.**

- `scripts/install.sh` runs the nix-darwin switch and then the home-manager switch.
  A sweep between the two deletes whatever the second step has not rooted yet. On
  2026-11-16 the nix-darwin sweep deleted 5,166 paths (8.0 GiB), including a
  home-manager build finished minutes earlier; the home-manager switch then rebuilt
  101 derivations and re-fetched 414 paths (479 MiB). The install took 8.5 minutes.
- The home-manager sweep is the last thing `install.sh` does, so nothing after it
  needs what it deletes. The same log shows it working as a non-root user
  (1,412 paths, 3.0 GiB freed).
- Disk use does not change: the retention policy is the same, only the timing moves.

**Accepted cost.** `dr:switch` on its own no longer reclaims space. Its garbage
(including the system generation it just pruned) waits for the next `hm:switch` or
`install.sh`.

## Ruled out

| Option | Why not |
|---|---|
| Weekly launchd job (prune + gc) | macOS Background Task Management can mark a launchd job "disallowed" with no visible failure; this already happened to `org.nixos.activate-system` on a team Mac. Jobs built by nix-darwin show in Login Items as `sh` from an unidentified developer. Pre-approving them needs a company-level Intune profile. |
| Determinate Nixd's collector alone | It acts on disk pressure (keep 30 GB free, settle at 5–20% free) and never prunes generations. About 97 GB of collectable garbage built up over six months with it enabled (PR #28). |
| `nix.gc.automatic` (nix-darwin) | Asserts `nix.enable`, which is `false` under Determinate Nix. |
| `nix.gc` (home-manager) | On macOS the launchd agent receives `options` as one argv element, so `--delete-older-than 14d` is rejected (home-manager issue #7211, open as of 2026-11-09). |
| Keep both sweeps, change only `/nix-upgrade` | Fixes that one command and leaves a mid-install sweep in place for everything else. |

## Deferred / revisit triggers

- **Keep more than one generation** (for example 14 days) — revisit if a bad bump
  ever needs a fast rollback. Estimated cost is one or two extra closures of about
  7 GiB each; not measured.
- **Scheduled cleanup** — revisit if teammates commonly go a month or more without
  switching, or if an MDM profile pre-approving the `org.nixos` and
  `systems.determinate` launchd label prefixes is put in place.
- **Disable Determinate Nixd's collector** — its docs advise against running a
  second collector. It is left on as a disk-pressure backstop; revisit if the two
  are ever seen to conflict.
- **`install.sh` re-downloads its own tooling each run** (322 MiB on 2026-11-16)
  because `nix run nix-darwin` is unpinned and the final sweep removes it. Fixing it
  means changing the shared install script; not done here.
