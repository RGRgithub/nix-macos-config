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
  #   neovim
  #   tmux
  #   ripgrep
  # ];

  # Personal shell aliases:
  # programs.fish.shellAliases = {
  #   "my-alias" = "some-command";
  # };

  # Personal environment variables:
  # home.sessionVariables = {
  #   MY_VAR = "value";
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
