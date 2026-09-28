# home-manager configuration: user-level, no sudo (apply with: hm:switch)
{
  lib,
  pkgs,
  hostInfo,
  gitInfo,
  direnvWhitelist,
  nix-vscode-extensions,
  ...
}:
{
  # home-manager compatibility marker; don't change.
  home.stateVersion = "25.11";

  home.username = hostInfo.username;
  home.homeDirectory = hostInfo.homedir;

  home.packages = with pkgs; [
    # Fish plugins
    fishPlugins.bass

    # CLI tools
    awscli2
    btop
    corepack_24
    gh
    google-cloud-sdk
    jq
    lazydocker
    lazygit
    ngrok
    nixfmt
    nil
    nodejs_24
    python314
    terraform
    terragrunt

    # GUI Applications
    maccy
    shottr
    slack
  ];

  home.sessionVariables = {
    EDITOR = "code --wait";
    PODMAN_COMPOSE_WARNING_LOGS = "false";
  };

  nixpkgs.overlays = [
    nix-vscode-extensions.overlays.default
    (final: prev: {
      # direnv's GNUmakefile forces -linkmode=external, which needs cgo; cgo
      # isn't available in the darwin nix build sandbox.
      direnv = prev.direnv.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace GNUmakefile \
            --replace "GO_LDFLAGS += -linkmode=external" ""
        '';
      });

      # Since 1.129, VSCode on macOS ships ripgrep under node_modules.asar.unpacked,
      # but nixpkgs' darwin postPatch still chmods the old node_modules path and
      # fails. That chmod is the whole darwin postPatch, so point it at the real path.
      vscode = prev.vscode.overrideAttrs (
        prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
          postPatch = ''
            chmod +x "Contents/Resources/app/node_modules.asar.unpacked/@vscode/ripgrep-universal/bin/darwin-arm64/rg"
          '';
        }
      );
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
    enableZshIntegration = false;
    enableFishIntegration = true;
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
        christian-kohler.npm-intellisense
        christian-kohler.path-intellisense
        dbaeumer.vscode-eslint
        esbenp.prettier-vscode
        hashicorp.terraform
        jnoortheen.nix-ide
        mkhl.direnv
        ms-python.python
        pkief.material-icon-theme
        redhat.vscode-yaml
      ])
      ++ (with pkgs.vscode-marketplace-release-universal; [
        anthropic.claude-code
        mermaidchart.vscode-mermaid-chart
        moonrepo.moon-console
        oxc.oxc-vscode
        the0807.git-graph-plus
      ]);

    profiles.default.userSettings = {
      "claudeCode.preferredLocation" = "panel";

      "chat.viewSessions.orientation" = "stacked";

      # Both must stay false. mkhl.direnv watches .direnv/flake-profile-*.rc,
      # which `use flake` rewrites on every load, so either setting sets off an
      # endless reload loop of `nix` evals. It OOM-wedged the machine in 2026-08.
      # Cost: an .envrc change needs a manual "Restart extensions?" click.
      # Revisit only if upstream stops watching files that `use flake` regenerates.
      "direnv.restart.automatic" = false;
      "direnv.watchForChanges" = false;

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
      "git.replaceTagsWhenPull" = true;

      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "${pkgs.nil}/bin/nil";
      "nix.formatterPath" = "nixfmt";
      "nix.serverSettings" = {
        "nil" = {
          "nix" = {
            # Fetch missing flake inputs without the "Fetch them now?" prompt.
            "flake" = {
              "autoArchive" = true;
            };
          };
        };
      };
      "[nix]" = {
        "editor.defaultFormatter" = "jnoortheen.nix-ide";
      };

      "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
      "terminal.integrated.fontSize" = 13;
      "terminal.integrated.cursorBlinking" = true;
      "terminal.integrated.cursorStyle" = "line";
      "terminal.integrated.profiles.osx" = {
        "fish" = {
          "path" = "${pkgs.fish}/bin/fish";
          "args" = [ "-l" ];
        };
      };
      "terminal.integrated.automationProfile.osx" = {
        "path" = "${pkgs.fish}/bin/fish";
        "args" = [ "-l" ];
      };
      "terminal.integrated.defaultProfile.osx" = "fish";
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
    completionInit = "autoload -U compinit && compinit -u";
  };

  programs.fish = {
    enable = true;

    shellAliases = {
      "hm:switch" =
        "home-manager switch --flake path:${hostInfo.flakedir}#${hostInfo.username} -b backup";
      "dr:switch" =
        "sudo -H darwin-rebuild switch --flake path:${hostInfo.flakedir}#${hostInfo.hostname}";
      "env:reload" = ''bass 'set -a; source "$HOME/.env"' '';
      "nix:install" = "${hostInfo.flakedir}/scripts/install.sh";
      "nix:uninstall" = "${hostInfo.flakedir}/scripts/uninstall.sh";
      "nix:update" = "nix flake update --flake path:${hostInfo.flakedir}";
      docker = "podman";
    };

    interactiveShellInit = "set -g fish_greeting \"\"";
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = false;
    enableFishIntegration = true;
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
    enableZshIntegration = false;
    enableFishIntegration = true;
    nix-direnv.enable = true;
    silent = true;
    # Auto-allow trusted .envrc files; edit the lists in variables/direnv-whitelist.nix.
    config.whitelist.prefix = direnvWhitelist.prefix;
    config.whitelist.exact = direnvWhitelist.exact;
  };

  # ~/.envrc loads ~/.env for any directory without its own .envrc; project
  # .envrc files opt in with source_up_if_exists.
  home.activation.setupDirenvHome = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.envrc" ]; then
      echo 'dotenv_if_exists $HOME/.env' > "$HOME/.envrc"
    fi
    ${pkgs.direnv}/bin/direnv allow "$HOME/.envrc"
  '';

  # ~/.env holds user secrets (never committed); symlinked into the repo for visibility.
  home.activation.createDotEnv = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.env" ]; then
      echo "Creating empty $HOME/.env for user secrets..."
      touch "$HOME/.env"
      chmod 600 "$HOME/.env"
    fi
    ln -sf "$HOME/.env" "${hostInfo.flakedir}/.env"
  '';

  home.activation.symlinkApplications = pkgs.lib.mkAfter ''
    echo "Creating symlink to Home Manager Apps in /Applications..."
    ln -sf "$HOME/Applications/Home Manager Apps" /Applications/ || true
  '';

  # Keep only the current generation of BOTH user profiles. home-manager's
  # expire-generations misses `profile`, which is where 90 GiB piled up.
  # nix.gc is unusable here: home-manager's darwin module passes `options` as a
  # single argv element, and nix-darwin's requires nix.enable (false for Determinate).
  # Keeping one generation is the only policy that reclaims the old closure after
  # a bump, because disk cost scales with distinct closures, not generation count.
  # Accepted cost: no --rollback; recover from git + flake.lock instead.
  # Revisit: change `old` to `+3` if a bad bump ever needs a fast rollback.
  home.activation.pruneUserProfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo "Pruning user profile generations (keeping only the current one)..."
    /nix/var/nix/profiles/default/bin/nix-env --profile "$HOME/.local/state/nix/profiles/profile" --delete-generations old
    /nix/var/nix/profiles/default/bin/nix-env --profile "$HOME/.local/state/nix/profiles/home-manager" --delete-generations old
  '';

  # Reclaim what the prune above just unpinned, then hard-link duplicate files.
  # This runs on hm:switch because that's the everyday switch and the one that
  # makes the big (Electron) garbage. Non-root gc/optimise work through the daemon.
  # `--max` is plain bytes. 20 GB exceeds one full closure swap, and the cap only
  # bounds latency on a pathological backlog.
  # Batch optimise instead of auto-optimise-store: auto-optimise would slow every
  # store write, and Determinate owns nix.conf so the setting would be a silent
  # no-op here anyway.
  home.activation.sweepStore = lib.hm.dag.entryAfter [ "pruneUserProfiles" ] ''
    echo "Sweeping store garbage (bounded at 20 GB)..."
    /nix/var/nix/profiles/default/bin/nix store gc --max 20000000000 2>&1 | tail -n 1
    echo "Deduplicating store files (hard-linking identical contents)..."
    /nix/var/nix/profiles/default/bin/nix store optimise 2>&1 | tail -n 1
  '';
}
