# nix-darwin configuration — system-level settings (applied with: dr:switch)
# These changes require sudo and affect the whole machine.
{
  pkgs,
  config,
  hostInfo,
  self,
  homebrew-core,
  homebrew-cask,
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
    shell = pkgs.zsh;
  };

  # Set the primary user for homebrew and other user-specific options
  system.primaryUser = hostInfo.username;

  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];

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
    };
  };

  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";
    onActivation.upgrade = true;
    taps = builtins.attrNames config.nix-homebrew.taps;
    brews = [
      "moon"
      "proto"
    ];

    casks = [
      "claude"
      "claude-code@latest"
      "microsoft-teams"
      "microsoft-outlook"
      "warp"
    ];
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # Remove unmanaged Homebrew Taps directories before nix-homebrew setup
  # to prevent "An existing .../Taps is in the way" errors on first switch
  system.activationScripts.cleanupHomebrewTaps = {
    before = [ "setup-homebrew" ];
    text = ''
      for taps_dir in /opt/homebrew/Library/Taps /usr/local/Homebrew/Library/Taps; do
        if [ -d "$taps_dir" ] && [ ! -L "$taps_dir" ]; then
          echo "Removing unmanaged Homebrew Taps directory: $taps_dir"
          rm -rf "$taps_dir"
        fi
      done
    '';
  };

  # Ensure the default shell is set correctly (only if not already zsh)
  system.activationScripts.postActivation.text = ''
    CURRENT_SHELL=$(dscl . -read /Users/${hostInfo.username} UserShell | awk '{print $2}')
    ZSH_PATH="/run/current-system/sw/bin/zsh"
    if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
      echo "Setting default shell to zsh..."
      /usr/bin/chsh -s "$ZSH_PATH" ${hostInfo.username} || echo "Failed to change shell"
    else
      echo "Default shell is already zsh, skipping chsh"
    fi
  '';
}
