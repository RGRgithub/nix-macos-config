# Personal user configuration
# ─────────────────────────────────────────────────────────────────────────────
# Add your own packages, aliases, and settings here. This file is for
# individual team member overrides on top of the shared home-configuration.nix.
#
# Apply changes with:  hm:switch
# ─────────────────────────────────────────────────────────────────────────────
{ ... }:
{
  # Extra packages just for you:
  # home.packages = with pkgs; [
  #   rbw
  # ];

  # If you want to manage ssh keys with bitwarden, you can set up the ssh agent and config like this:
  # programs.ssh = {
  #   enable = true;
  #   enableDefaultConfig = false;
  #   matchBlocks."*".identityAgent = "~/.bitwarden-ssh-agent.sock";
  # };

  # home.sessionVariables = {
  #   SSH_AUTH_SOCK = "~/.bitwarden-ssh-agent.sock";
  # };

  # Personal VSCode extensions (on top of the shared ones):
  # programs.vscode.profiles.default.extensions = with pkgs.vscode-marketplace; [
  #   publisher.extension-name
  # ];

  # Personal VSCode settings overrides:
  # programs.vscode.profiles.default.userSettings = {
  #   "editor.fontSize" = 14;
  # };
}
