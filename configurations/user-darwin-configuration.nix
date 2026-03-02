# Personal nix-darwin configuration
# ─────────────────────────────────────────────────────────────────────────────
# Add your own Homebrew casks and system-level settings here.
# These are merged on top of the shared darwin-configuration.nix.
#
# Apply changes with:  dr:switch
# ─────────────────────────────────────────────────────────────────────────────
{ ... }:
{
  # Add your personal Homebrew casks here:
  # homebrew.casks = [
  #   "thebrowsercompany-dia"
  # ];

  # Add your personal system packages here:
  # environment.systemPackages = with pkgs; [
  #   some-package
  # ];
}
