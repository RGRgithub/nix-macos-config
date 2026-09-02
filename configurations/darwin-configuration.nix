# nix-darwin configuration — system-level settings (applied with: dr:switch)
# These changes require sudo and affect the whole machine.
{
  pkgs,
  config,
  hostInfo,
  self,
  homebrew-core,
  homebrew-cask,
  homebrew-shotx,
  ...
}:
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (final: prev: {
      direnv = prev.direnv.overrideAttrs (_: {
        doCheck = false;
      });
    })
  ];
  nix.settings.experimental-features = "nix-command flakes";
  nix.enable = false;

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = false;
  };
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility. please read the changelog
  # before changing: `darwin-rebuild changelog`.
  system.stateVersion = 4;

  # Declare the user that will be running `nix-darwin`.
  users.users.${hostInfo.username} = {
    name = hostInfo.username;
    home = hostInfo.homedir;
    shell = pkgs.fish;
  };

  # Set the primary user for homebrew and other user-specific options
  system.primaryUser = hostInfo.username;

  programs.fish.enable = true;
  programs.zsh.enable = true;
  environment.shells = [
    pkgs.fish
    pkgs.zsh
  ];

  environment.systemPackages = with pkgs; [
    git
    zsh
    openssh
  ];

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    autoMigrate = true;
    mutableTaps = false;
    user = hostInfo.username;
    taps = {
      "homebrew/homebrew-core" = homebrew-core;
      "homebrew/homebrew-cask" = homebrew-cask;
      "aimen08/homebrew-shotx" = homebrew-shotx;
    };
  };

  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";
    onActivation.upgrade = true;
    taps = builtins.attrNames config.nix-homebrew.taps;
    brews = [
      "moon"
      "podman"
      "podman-compose"
      "proto"
    ];

    casks = [
      "brave-browser"
      "bitwarden"
      "bruno"
      "claude"
      "claude-code@latest"
      "ghostty"
      "google-chrome"
      "jordanbaird-ice"
      "loop"
      "podman-desktop"
      "raycast"
      "shotx"
      "spotify"
      "warp"
      "zoom"
    ];
  };

  # Homebrew 6.x defaults HOMEBREW_REQUIRE_TAP_TRUST=true, so casks from
  # third-party taps (e.g. shotx, from aimen08/homebrew-shotx) are refused
  # unless trusted with `brew trust`. That trust lives in a per-user file keyed
  # off $USER, which isn't reliably present in the non-interactive activation
  # context — and `brew cleanup` re-evaluates every installed cask, so it fails
  # too. `bin/brew` sources /etc/homebrew/brew.env at startup (before sudo strips
  # the env), so disabling the trust requirement here applies to bundle and
  # cleanup for every user, with no fragile trust.json to maintain.
  environment.etc."homebrew/brew.env".text = ''
    HOMEBREW_NO_REQUIRE_TAP_TRUST=1
  '';

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # Remove unmanaged Homebrew Taps directories before nix-homebrew setup
  # to prevent "An existing .../Taps is in the way" errors on first switch
  # Wired via the `homebrew` hook with mkOrder 400, NOT as its own named script.
  # nix-darwin's activate script string-interpolates a HARDCODED list of ~25 script
  # names -- there is no DAG, and `before`/`after` are not options on these
  # submodules. An arbitrary `system.activationScripts.<name>` is therefore never
  # referenced, never merged, and never even type-checked (attrsOf is lazy per
  # attribute) -- which is why the invalid `before = [ "setup-homebrew" ]` this
  # block used to carry slid through evaluation with no error, and why the cleanup
  # never ran once. Confirmed 2026-08-21: it was absent from
  # /run/current-system/activate while setup-homebrew and brew bundle were present.
  # A build does NOT catch this class of mistake.
  #
  # nix-homebrew injects setup-homebrew into this same hook at mkBefore (order 500),
  # so mkOrder 400 lands immediately before it -- the originally intended position.
  system.activationScripts.homebrew.text = pkgs.lib.mkOrder 400 ''
    for taps_dir in /opt/homebrew/Library/Taps /usr/local/Homebrew/Library/Taps; do
      if [ -d "$taps_dir" ] && [ ! -L "$taps_dir" ]; then
        echo "Removing unmanaged Homebrew Taps directory: $taps_dir"
        rm -rf "$taps_dir"
      fi
    done
  '';

  # Prune old darwin system generations on every switch.
  # Counterpart to home.activation.pruneUserProfiles in home-configuration.nix --
  # see that block for the full rationale and for why nix.gc was ruled out
  # (nix-darwin asserts `nix.gc.automatic -> nix.enable`, and we set
  # nix.enable = false for Determinate Nix).
  #
  # By 2026-08-21 this profile had 239 generations going back to February,
  # straddling two nixpkgs channels (187 on 26.05, 52 on 26.11).
  # `old` never deletes the current generation, so the running system is never at
  # risk -- but it does leave nothing to `darwin-rebuild --rollback` to. That cost
  # was accepted deliberately on 2026-08-31; the measurements behind it are in the
  # RETENTION block in home-configuration.nix.
  # Ensure the default shell is set correctly (only if not already zsh)
  system.activationScripts.postActivation.text = pkgs.lib.mkMerge [
    (''
      CURRENT_SHELL=$(dscl . -read /Users/${hostInfo.username} UserShell | awk '{print $2}')
      FISH_PATH="/run/current-system/sw/bin/fish"
      if [ "$CURRENT_SHELL" != "$FISH_PATH" ]; then
        echo "Setting default shell to fish..."
        /usr/bin/chsh -s "$FISH_PATH" ${hostInfo.username} || echo "Failed to change shell"
      else
        echo "Default shell is already fish, skipping chsh"
      fi

      # Prune old darwin system generations (see the block comment above).
      # This lives in postActivation rather than its own
      # `system.activationScripts.<name>` because an arbitrary named script is NOT
      # wired into nix-darwin's activation graph -- it evaluates fine, gets built,
      # and then silently never runs. Verified 2026-08-21: neither
      # `pruneSystemGenerations` nor the existing `cleanupHomebrewTaps` appears in
      # /run/current-system/activate, while this postActivation block does. A build
      # will NOT catch that mistake, so keep new activation work in here.
      echo "Pruning system generations (keeping only the current one)..."
      /nix/var/nix/profiles/default/bin/nix-env --profile /nix/var/nix/profiles/system --delete-generations old
    '')

    # Bounded store sweep, ordered AFTER every prune in this switch.
    #
    # Why it is needed: determinate-nixd's auto-GC is enabled by default, but it is
    # throughput-limited, not trigger-limited. It evaluates its rubric on daemon
    # start and roughly every 2h, then spawns `nix store gc --max 1000000000` --
    # exactly 1 GB per firing, then backs off on hysteresis. Measured on this
    # machine: 23 firings between 2026-07-15 and 2026-08-21, ~1 GB each, ~0.6 GB/day.
    # It also collected NOTHING before 2026-07-15 despite being "enabled" since
    # February -- the executor effectively began working in Determinate Nix 3.21.5.
    # That drain rate is well under a dev-heavy month's ~10-20 GB of churn, which is
    # how ~97 GB of collectable garbage accumulated unnoticed by 2026-08-21.
    #
    # `--max` takes PLAIN BYTES -- no "20G" suffix (the daemon itself passes
    # 1000000000). Raised from 5 GB to 20 GB on 2026-08-31 alongside the switch to
    # keep-only-current retention: under that policy a flake bump orphans a whole
    # closure at once (~6 GB, against 7.62 GB of new paths on the 2026-08-31 bump),
    # so a 5 GB cap would bind on every bump and silently carry garbage forward.
    # The cap now exists only to bound switch latency in a pathological backlog.
    # Deletion order is arbitrary; anything left over is swept by the next switch.
    #
    # pkgs.lib.mkAfter orders this last within postActivation, i.e. after the system
    # generation prune above -- so THIS switch's system garbage is swept immediately.
    #
    # This sweep covers a standalone `dr:switch`. The everyday `hm:switch` path is
    # covered by home.activation.sweepStore, which also runs after the user-profile
    # prune inside the same activation -- see that block for why the sweep needed to
    # exist on the home-manager side too, and for the verification that non-root
    # `nix store gc` is not refused by the daemon on this machine.
    #
    # Nothing the switch just built is at risk: the new system closure is rooted via
    # /nix/var/nix/profiles/system, and in-flight builds hold temp roots.
    (pkgs.lib.mkAfter ''
      echo "Sweeping store garbage (bounded at 20 GB)..."
      /nix/var/nix/profiles/default/bin/nix store gc --max 20000000000 2>&1 | tail -n 1
    '')
  ];
}
