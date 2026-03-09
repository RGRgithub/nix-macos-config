# home-manager configuration — user-level settings (applied with: hm:switch)
# These changes don't require sudo and affect only the current user.
{
  lib,
  pkgs,
  hostInfo,
  gitInfo,
  nix-vscode-extensions,
  ...
}:
{
  # this is internal compatibility configuration
  # for home-manager, don't change this!
  home.stateVersion = "25.11";

  home.username = hostInfo.username;
  home.homeDirectory = hostInfo.homedir;

  home.packages = with pkgs; [
    # CLI tools
    btop
    claude-code
    corepack_24
    gemini-cli
    gh
    lazygit
    ngrok
    nixfmt
    nil
    nodejs_24
    podman
    podman-compose
    python315
    sqlit-tui

    # GUI Applications
    bitwarden-desktop
    brave
    bruno
    ghostty-bin
    google-chrome
    ice-bar
    loopwm
    maccy
    podman-desktop
    raycast
    shottr
    slack
    spotify
  ];

  home.sessionVariables = {
    EDITOR = "code --wait";
    PODMAN_COMPOSE_WARNING_LOGS = "false";

    # https://github.com/Maxteabag/sqlit/issues/111
    SQLIT_PROCESS_WORKER = 0;
  };

  nixpkgs.overlays = [
    nix-vscode-extensions.overlays.default
  ];

  programs.git = lib.optionalAttrs (gitInfo ? name && gitInfo ? email) {
    enable = true;
    settings.init.defaultBranch = "main";
    settings.core.editor = "code --wait";
    settings.user.name = gitInfo.name;
    settings.user.email = gitInfo.email;
  };

  programs.lazygit = {
    enable = true;
    enableFishIntegration = true;
    package = pkgs.lazygit;
  };

  # Let home-manager install and manage itself.
  programs.home-manager.enable = true;

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    profiles.default.extensions =
      # Extensions from base nixpkgs (more stable, better maintained)
      (with pkgs.vscode-extensions; [
        anthropic.claude-code
        christian-kohler.npm-intellisense
        christian-kohler.path-intellisense
        dbaeumer.vscode-eslint
        esbenp.prettier-vscode
        jnoortheen.nix-ide
        pkief.material-icon-theme
      ])
      ++
        # Extensions from nix-vscode-extensions marketplace
        (with pkgs.vscode-marketplace; [
          mermaidchart.vscode-mermaid-chart
        ]);

    profiles.default.userSettings = {
      "claudeCode.preferredLocation" = "panel";

      "chat.viewSessions.orientation" = "stacked";

      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.formatOnSave" = true;
      "editor.fontFamily" = "JetBrainsMono Nerd Font";
      "editor.fontSize" = 13;
      "editor.fontLigatures" = true;
      "editor.renderWhitespace" = "all";

      "git.autofetch" = true;
      "git.blame.editorDecoration.enabled" = true;
      "git.blame.statusBarItem.enabled" = true;
      "git.confirmSync" = false;
      "git.rebaseWhenSync" = true;

      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "${pkgs.nil}/bin/nil";
      "nix.formatterPath" = "nixfmt";
      "[nix]" = {
        "editor.defaultFormatter" = "jnoortheen.nix-ide";
      };

      "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
      "terminal.integrated.fontSize" = 13;
      "terminal.integrated.cursorBlinking" = true;
      "terminal.integrated.cursorStyle" = "line";
      "terminal.integrated.defaultProfile.osx" = "fish";
      "terminal.integrated.enablePersistentSessions" = false;
      "terminal.integrated.environmentChangesRelaunch" = true;
      "terminal.integrated.hideOnLastClosed" = false;
      "terminal.integrated.hideOnStartup" = "always";

      "window.nativeTabs" = true;
      "window.restoreWindows" = "preserve";

      "workbench.iconTheme" = "material-icon-theme";

      "update.mode" = "none";
    };
  };

  programs.fish = {
    enable = true;
    shellAliases = {
      "hm:switch" = "home-manager switch --flake path:${hostInfo.flakedir} -b backup";
      docker = "podman"; # Docker compatibility
    };
  };

  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
    nix-direnv.enable = true;
    silent = true;
  };

  # Symlink Home Manager Apps to main Applications folder for visibility
  home.activation.symlinkApplications = pkgs.lib.mkAfter ''
    echo "Creating symlink to Home Manager Apps in /Applications..."
    ln -sf "$HOME/Applications/Home Manager Apps" /Applications/ || true
  '';
}
