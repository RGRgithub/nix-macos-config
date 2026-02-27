{
  description = "My system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    mac-app-util.url = "github:hraban/mac-app-util";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nix-darwin,
      home-manager,
      mac-app-util,
      nix-vscode-extensions,
      nixpkgs,
      ...
    }:
    let
      # Import host-specific information
      hostInfo = import ./host-info.nix;
      gitInfo = import ./git-info.nix;

      # nix-darwin configuration (system-level, requires sudo)
      darwinConfiguration =
        { pkgs, ... }:
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
              "nix:install" = "${hostInfo.flakedir}/install.sh";
              "nix:uninstall" = "${hostInfo.flakedir}/uninstall.sh";
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
        };

      # home-manager configuration (user-level, no sudo required)
      homeConfiguration =
        { lib, pkgs, ... }:
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
            nixfmt
            nil
            nodejs_24
            podman
            podman-compose
            python315
            rbw

            # GUI Applications
            bitwarden-desktop
            brave
            ghostty-bin
            google-chrome
            ice-bar
            maccy
            podman-desktop
            postman
            raycast
            shottr
            slack
            spotify
            warp-terminal
          ];

          home.sessionVariables = {
            EDITOR = "code --wait";
            PODMAN_COMPOSE_WARNING_LOGS = "false";
          };

          nixpkgs.overlays = [
            nix-vscode-extensions.overlays.default
          ];

          programs.git = lib.optionalAttrs (gitInfo ? name && gitInfo ? email) {
            enable = true;
            settings.core.editor = "code --wait";
            settings.user.name = gitInfo.name;
            settings.user.email = gitInfo.email;
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
              "terminal.integrated.environmentChangesRelaunch" = true;
              "terminal.integrated.hideOnLastClosed" = false;

              "window.nativeTabs" = true;
              "window.restoreWindows" = "preserve";

              "workbench.iconTheme" = "material-icon-theme";

              "update.mode" = "none";
            };
          };

          programs.fish = {
            enable = true;
            shellAliases = {
              "hm:switch" = "home-manager switch --flake ${hostInfo.flakedir}";
              docker = "podman"; # Docker compatibility
            };
          };

          # Symlink Home Manager Apps to main Applications folder for visibility
          home.activation.symlinkApplications = pkgs.lib.mkAfter ''
            echo "Creating symlink to Home Manager Apps in /Applications..."
            ln -sf "$HOME/Applications/Home Manager Apps" /Applications/ || true
          '';
        };
    in
    {
      # nix-darwin configuration (apply with: darwin-rebuild switch --flake ~/.config/nix)
      darwinConfigurations.${hostInfo.hostname} = nix-darwin.lib.darwinSystem {
        modules = [
          darwinConfiguration
          mac-app-util.darwinModules.default
        ];
      };

      # Standalone home-manager configuration (apply with: home-manager switch --flake ~/.config/nix)
      homeConfigurations.${hostInfo.username} = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true;
        };
        modules = [
          homeConfiguration
          mac-app-util.homeManagerModules.default
        ];
      };
    };
}
