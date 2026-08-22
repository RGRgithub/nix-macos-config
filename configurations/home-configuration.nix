# home-manager configuration — user-level settings (applied with: hm:switch)
# These changes don't require sudo and affect only the current user.
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
  # this is internal compatibility configuration
  # for home-manager, don't change this!
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
      # direnv 2.37.1 sets -linkmode=external in its GNUmakefile which requires
      # cgo, but cgo is not available in the nix build environment on macOS.
      direnv = prev.direnv.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace GNUmakefile \
            --replace "GO_LDFLAGS += -linkmode=external" ""
        '';
      });

      # VSCode 1.129 ships node_modules.asar(.unpacked) on macOS, but nixpkgs'
      # postPatch only extracts a plain node_modules from the asar on Linux. On
      # darwin its ripgrep step still chmods Contents/Resources/app/node_modules/
      # @vscode/ripgrep-universal/bin/darwin-arm64/rg — a path that never exists —
      # so the build dies with "chmod: cannot access ...". On darwin that ripgrep
      # step is the entire postPatch, so replace it with a chmod of the binary's
      # real location under node_modules.asar.unpacked.
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

      # Deliberately FALSE. Enabling this restarts the extension host on every
      # "environment change", but mkhl.direnv watches
      # .direnv/flake-profile-<hash>.rc -- the very file `use flake` rewrites on
      # each evaluation. That closes a loop: rewrite -> restart -> re-evaluate ->
      # rewrite. On 2026-08-21 it ran away in rgr-platform at ~135 shell spawns/sec
      # (964 concurrent `nix` evals, ~100 GB footprint), pinned the VM compressor
      # and wedged the machine hard enough to need a power cycle. Jetsam killed
      # ~940 processes across three events before the reboot.
      #
      # Trade-off accepted: we get the "direnv: Environment updated. Restart
      # extensions?" prompt back on new empty windows. That prompt is the reason
      # this was true in the first place -- an annoyance is preferable to an OOM.
      #
      # Reopen only if the extension stops watching files that `use flake`
      # rewrites (upstream fix), not merely because the prompt is irritating.
      "direnv.restart.automatic" = false;

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
      # Settings forwarded to the language server (nil) by the nix-ide extension.
      "nix.serverSettings" = {
        "nil" = {
          "nix" = {
            # Fetch missing flake inputs automatically instead of showing the
            # "Some flake inputs are not available. Fetch them now?" prompt on
            # every flake repo. Unset/null means "ask"; false means "never
            # fetch" (and report missing inputs as diagnostics instead).
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

  programs.tmux = {
    enable = true;
    # Mouse off: the tmux-integrated VSCode extension keeps tmux invisible in
    # the background and lets VSCode handle scroll/click natively. tmux mouse
    # mode would fight with that and reintroduce the wheel-scroll latency.
    mouse = false;
    plugins = with pkgs; [
      tmuxPlugins.sensible
    ];
    extraConfig = ''
      set -g default-terminal "tmux-256color"
      set -g status-position top
      set -g status-left-length 120
      set -g status-left "  #[bold]#(whoami)#[nobold] in #S  "
      set -g status-right ""
      set -g window-status-format "  #W  "
      set -g window-status-current-format "  #W  "
      set -as terminal-overrides ',xterm*:Tc:sitm=\E[3m'
      set -g status-style "fg=default,bg=#007ACC"
      set -g window-status-style "fg=default,bg=#007ACC"
      set -g window-status-current-style "fg=default,bg=default,reverse,bold"
    '';
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = false;
    enableFishIntegration = true;
    nix-direnv.enable = true;
    silent = true;
    # Whitelist specific trusted .envrc files so direnv loads them without the
    # "is blocked" prompt (the mkhl.direnv VS Code extension has no auto-allow
    # setting — this is direnv's own whitelist mechanism). `prefix` entries are
    # repos (covers git worktrees created on the fly under them); `exact` is the
    # home-level ~/.envrc only. Edit the lists in variables/direnv-whitelist.nix.
    config.whitelist.prefix = direnvWhitelist.prefix;
    config.whitelist.exact = direnvWhitelist.exact;
  };

  # Load ~/.env for all shells via direnv — any directory without its own
  # .envrc inherits this; project .envrc files opt in with source_up_if_exists.
  home.activation.setupDirenvHome = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.envrc" ]; then
      echo 'dotenv_if_exists $HOME/.env' > "$HOME/.envrc"
    fi
    ${pkgs.direnv}/bin/direnv allow "$HOME/.envrc"
  '';

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

  # Prune old generations of BOTH user profiles on every switch.
  #
  # Why this exists: home-manager activation installs its package set into the
  # *default user profile* (~/.local/state/nix/profiles/profile) via nix-env, one
  # generation per switch. Nothing pruned it for six months, so by 2026-08-21 it
  # held 208 generations pinning 113.7 GiB -- 90.5 GiB of that reachable from
  # nothing else -- and /nix had grown to 224 GB. It is mostly repeated snapshots
  # of Electron apps (vscode, chrome, brave, podman-desktop, bruno, bitwarden),
  # which is why each generation costs ~435 MB.
  #
  # Note BOTH profiles are pruned. `home-manager expire-generations` only touches
  # the `home-manager` profile, and `sudo nix-collect-garbage` only touches root's
  # profiles + /nix/var/nix/profiles -- so the `profile` one below is the exact gap
  # that let 90 GiB accumulate unnoticed.
  #
  # Ruled out: `nix.gc.automatic` (home-manager). On Darwin that module builds
  # launchd ProgramArguments as
  #   [ "nix-collect-garbage" ] ++ lib.optional (cfg.options != null) cfg.options
  # so a multi-word `options` becomes ONE argv element. Verified empirically:
  # `nix-collect-garbage "--delete-older-than 7d"` => "unrecognised flag", and the
  # `--delete-older-than=7d` equals form is not accepted either. So no time window
  # of any length can be expressed through that module on macOS; only a single
  # token like `-d` survives. nix-darwin's `nix.gc` is a non-starter separately --
  # it asserts `cfg.automatic -> config.nix.enable`, and we set nix.enable = false
  # for Determinate Nix.
  #
  # Deliberately no GC here: pruning only removes symlinks (instant, takes no store
  # lock), and determinate-nixd's own rubric GC vacuums the unpinned paths after.
  # That keeps install.sh from growing a long lock-holding GC phase.
  #
  # 7d never deletes the current generation, so a working system always remains.
  # Revisit only if rollback to something older than a week is actually wanted.
  home.activation.pruneUserProfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo "Pruning user profile generations older than 7 days..."
    /nix/var/nix/profiles/default/bin/nix-env --profile "$HOME/.local/state/nix/profiles/profile" --delete-generations 7d
    /nix/var/nix/profiles/default/bin/nix-env --profile "$HOME/.local/state/nix/profiles/home-manager" --delete-generations 7d
  '';
}
