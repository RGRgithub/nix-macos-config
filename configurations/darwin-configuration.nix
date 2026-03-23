# nix-darwin configuration — system-level settings (applied with: dr:switch)
# These changes require sudo and affect the whole machine.
{
  pkgs,
  hostInfo,
  self,
  ...
}:
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = "nix-command flakes";
  nix.enable = false;

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
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

  programs.fish = {
    enable = true;
    shellAliases = {
      "dr:switch" =
        "sudo -H darwin-rebuild switch --flake path:${hostInfo.flakedir}#${hostInfo.hostname}";
      "nix:install" = "${hostInfo.flakedir}/scripts/install.sh";
      "nix:uninstall" = "${hostInfo.flakedir}/scripts/uninstall.sh";
      "nix:update" = "nix flake update --flake path:${hostInfo.flakedir}";
    };
  };
  environment.shells = [ pkgs.fish ];

  environment.systemPackages = with pkgs; [
    git
    git-lfs
    fish
    openssh
  ];

  nix-homebrew = {
    enable = true;
    enableRosetta = true;

    # some casks (like microsoft-outlook) can require updating taps during build.
    # we allow mutable taps so that the derivation can write the necessary files
    # at evaluation time. this prevents an empty buildCommand which caused the
    # `taps-env.drv` to produce no output and fail.
    mutableTaps = true;
    user = hostInfo.username;
  };

  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";
    casks = [
      "microsoft-teams"
      "microsoft-outlook"
      "warp"
    ];
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # Ensure the default shell is set correctly (only if not already fish)
  system.activationScripts.postActivation.text = ''
    CURRENT_SHELL=$(dscl . -read /Users/${hostInfo.username} UserShell | awk '{print $2}')
    FISH_PATH="/run/current-system/sw/bin/fish"
    if [ "$CURRENT_SHELL" != "$FISH_PATH" ]; then
      echo "Setting default shell to fish..."
      /usr/bin/chsh -s "$FISH_PATH" ${hostInfo.username} || echo "Failed to change shell"
    else
      echo "Default shell is already fish, skipping chsh"
    fi
  '';
}
