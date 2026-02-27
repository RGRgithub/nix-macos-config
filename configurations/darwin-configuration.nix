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

  security.pam.services.sudo_local.touchIdAuth = true;
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
      "dr:switch" = "sudo -H darwin-rebuild switch --flake ${hostInfo.flakedir}";
      "nix:install" = "${hostInfo.flakedir}/scripts/install.sh";
      "nix:uninstall" = "${hostInfo.flakedir}/scripts/uninstall.sh";
    };
  };
  environment.shells = [ pkgs.fish ];

  environment.systemPackages = with pkgs; [
    git
    fish
    openssh
  ];

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
