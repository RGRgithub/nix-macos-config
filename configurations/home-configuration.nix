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
    corepack_24
    gemini-cli
    gh
    google-cloud-sdk
    lazydocker
    lazygit
    ngrok
    nixfmt
    nil
    nodejs_24
    podman
    podman-compose
    python314
    terraform

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
  };

  home.sessionVariablesExtra = ''
    # Source user secrets from ~/.env (create this file manually, never commit it)
    if [ -f "$HOME/.env" ]; then
      set -a
      source "$HOME/.env"
      set +a
    fi
  '';

  nixpkgs.overlays = [
    nix-vscode-extensions.overlays.default
    (final: prev: {
      # direnv 2.37.1 sets -linkmode=external in its GNUmakefile which requires
      # cgo, but cgo is not available in the nix build environment on macOS.
      direnv = prev.direnv.overrideAttrs (old: {
        doCheck = false;
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
        bierner.markdown-mermaid
        christian-kohler.npm-intellisense
        christian-kohler.path-intellisense
        dbaeumer.vscode-eslint
        esbenp.prettier-vscode
        hashicorp.terraform
        jnoortheen.nix-ide
        mkhl.direnv
        pkief.material-icon-theme
        redhat.vscode-yaml
      ])
      ++ (with pkgs.vscode-marketplace-release-universal; [
        anthropic.claude-code
        mermaidchart.vscode-mermaid-chart
        moonrepo.moon-console
        oxc.oxc-vscode
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

      "update.mode" = "none";

      "window.nativeTabs" = true;
      "window.restoreWindows" = "preserve";

      "workbench.colorTheme" = "Dark+";
      "workbench.iconTheme" = "material-icon-theme";

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
      "env:reload" = "source \"$HOME/.env\"";
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

  programs.tmux = {
    enable = true;
    mouse = true;
    plugins = with pkgs; [
      tmuxPlugins.sensible
    ];
    extraConfig = ''
      set -g status-position top
      set -g status-left-length 120
      set -g status-left "  #[bold]#(whoami)#[nobold] in #S  "
      set -g status-right ""
      set -g window-status-format "  #W  "
      set -g window-status-current-format "  #W  "
      set -as terminal-overrides ",xterm-ghostty:RGB"
      set -g status-style "fg=default,bg=#007ACC"
      set -g window-status-style "fg=default,bg=#007ACC"
      set -g window-status-current-style "fg=default,bg=default,reverse,bold"
    '';
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    silent = true;
  };

  # Create ~/.env if it doesn't exist (used for user secrets, never committed)
  # and symlink it into the repo so it's visible in the VS Code explorer
  home.activation.createDotEnv = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.env" ]; then
      echo "Creating empty $HOME/.env for user secrets..."
      touch "$HOME/.env"
      chmod 600 "$HOME/.env"
    fi
    ln -sf "$HOME/.env" "${hostInfo.flakedir}/.env"
  '';

  # Symlink Home Manager Apps to main Applications folder for visibility
  home.activation.symlinkApplications = pkgs.lib.mkAfter ''
    echo "Creating symlink to Home Manager Apps in /Applications..."
    ln -sf "$HOME/Applications/Home Manager Apps" /Applications/ || true
  '';
}
