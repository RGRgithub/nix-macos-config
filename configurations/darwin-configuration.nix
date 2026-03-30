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
    brews = [
    ];

    casks = [
      "claude"
      "microsoft-teams"
      "microsoft-outlook"
      "warp"
    ];
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

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
