# nix-darwin configuration: system-level, needs sudo (apply with: dr:switch)
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
  nix.enable = false;

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = false;
  };
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Compatibility marker; read `darwin-rebuild changelog` before changing.
  system.stateVersion = 4;

  users.users.${hostInfo.username} = {
    name = hostInfo.username;
    home = hostInfo.homedir;
    shell = pkgs.fish;
  };

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
    # Homebrew refuses to load non-official taps (e.g. aimen08/homebrew-shotx)
    # unless they're trusted. Every tap is pinned as a flake input, so trust them all.
    # `brew bundle --force-cleanup` rewrites ~/.homebrew/trust.json to exactly this
    # on every switch, so a manual `brew trust` won't stick. Trust is written only
    # for the primary user's default config home: other macOS users, or a set
    # XDG_CONFIG_HOME, get "untrusted tap" errors from interactive brew.
    taps = map (name: {
      inherit name;
      trusted = true;
    }) (builtins.attrNames config.nix-homebrew.taps);
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

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # Remove unmanaged Taps dirs that block nix-homebrew ("Taps is in the way").
  # This must hook the `homebrew` script: nix-darwin only runs a hardcoded list of
  # activation scripts, so a custom-named one builds fine but never runs.
  # mkOrder 400 puts it just before nix-homebrew's setup-homebrew (mkBefore = 500).
  system.activationScripts.homebrew.text = pkgs.lib.mkOrder 400 ''
    for taps_dir in /opt/homebrew/Library/Taps /usr/local/Homebrew/Library/Taps; do
      if [ -d "$taps_dir" ] && [ ! -L "$taps_dir" ]; then
        echo "Removing unmanaged Homebrew Taps directory: $taps_dir"
        rm -rf "$taps_dir"
      fi
    done
  '';

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

      # Keep only the current system generation (policy: see pruneUserProfiles in
      # home-configuration.nix). It's here and not a named script for the same
      # reason as the Taps cleanup above.
      echo "Pruning system generations (keeping only the current one)..."
      /nix/var/nix/profiles/default/bin/nix-env --profile /nix/var/nix/profiles/system --delete-generations old
    '')

    # Sweep this switch's garbage (mkAfter = after the prune above).
    # determinate-nixd's auto-GC frees only ~1 GB per run, far below real churn.
    # The 20 GB cap is plain bytes; see sweepStore in home-configuration.nix.
    (pkgs.lib.mkAfter ''
      echo "Sweeping store garbage (bounded at 20 GB)..."
      /nix/var/nix/profiles/default/bin/nix store gc --max 20000000000 2>&1 | tail -n 1
    '')
  ];
}
