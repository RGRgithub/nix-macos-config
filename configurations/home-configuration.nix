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
    google-cloud-sdk
    lazydocker
    lazygit
    ngrok
    mcp-nixos
    nixfmt
    nil
    nodejs_24
    podman
    podman-compose
    python315
    sqlit-tui
    tmux

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
    zoom-us
  ];

  home.sessionVariables = {
    EDITOR = "code --wait";
    PODMAN_COMPOSE_WARNING_LOGS = "false";

    # https://github.com/Maxteabag/sqlit/issues/111
    SQLIT_PROCESS_WORKER = 0;
  };

  nixpkgs.overlays = [
    nix-vscode-extensions.overlays.default
    (final: prev: {
      # direnv 2.37.1 sets -linkmode=external in its GNUmakefile which requires
      # cgo, but cgo is not available in the nix build environment on macOS.
      direnv = prev.direnv.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace GNUmakefile \
            --replace "GO_LDFLAGS += -linkmode=external" ""
        '';
      });
    })
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
    enableZshIntegration = true;
    package = pkgs.lazygit;
  };

  # Let home-manager install and manage itself.
  programs.home-manager.enable = true;

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    mutableExtensionsDir = false;
    profiles.default.extensions =
      # Extensions from base nixpkgs (more stable, better maintained)
      (with pkgs.vscode-extensions; [
        anthropic.claude-code
        christian-kohler.npm-intellisense
        christian-kohler.path-intellisense
        dbaeumer.vscode-eslint
        esbenp.prettier-vscode
        jnoortheen.nix-ide
        mkhl.direnv
        pkief.material-icon-theme
        redhat.vscode-yaml
      ])
      ++
        # Extensions from nix-vscode-extensions marketplace
        (with pkgs.vscode-marketplace; [
          mermaidchart.vscode-mermaid-chart
          moonrepo.moon-console
          zeroregister.vscode-tmux-manager
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
      "terminal.integrated.defaultProfile.osx" = "zsh";
      "terminal.integrated.enablePersistentSessions" = false;
      "terminal.integrated.environmentChangesRelaunch" = true;
      "terminal.integrated.hideOnLastClosed" = false;
      "terminal.integrated.hideOnStartup" = "always";
      "terminal.integrated.initialHint" = false;

      "redhat.telemetry.enabled" = false;

      "window.nativeTabs" = true;
      "window.restoreWindows" = "preserve";

      "workbench.iconTheme" = "material-icon-theme";

      "update.mode" = "none";
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    shellAliases = {
      "hm:switch" =
        "home-manager switch --flake path:${hostInfo.flakedir}#${hostInfo.username} -b backup";
      "dr:switch" =
        "sudo -H darwin-rebuild switch --flake path:${hostInfo.flakedir}#${hostInfo.hostname}";
      "nix:install" = "${hostInfo.flakedir}/scripts/install.sh";
      "nix:uninstall" = "${hostInfo.flakedir}/scripts/uninstall.sh";
      "nix:update" = "nix flake update --flake path:${hostInfo.flakedir}";
      docker = "podman";
    };

    history = {
      size = 10000;
      save = 10000;
      share = true;
      extended = true;
      ignoreDups = true;
      ignoreAllDups = true;
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    presets = [ "nerd-font-symbols" ];
    settings = {
      format = "$os$username$directory$git_branch$cmd_duration$line_break$time$character";

      gcloud.disabled = true;
      git_status.disabled = true;
      nodejs.disabled = true;

      os.disabled = false;

      username = {
        show_always = true;
        style_user = "bold";
      };
    };
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    silent = true;
  };

  # Symlink Home Manager Apps to main Applications folder for visibility
  home.activation.symlinkApplications = pkgs.lib.mkAfter ''
    echo "Creating symlink to Home Manager Apps in /Applications..."
    ln -sf "$HOME/Applications/Home Manager Apps" /Applications/ || true
  '';
}
