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
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
      inputs.brew-src.follows = "brew-src";
    };
    # TEMPORARY. nix-homebrew pins brew-src to 6.0.12, but the
    # homebrew-core/homebrew-cask taps track HEAD and have moved on to a 6.0.13
    # DSL — they call InstallSteps::DSL#run and #terminate_process, neither of
    # which exists on that class in 6.0.12. Without this, `brew bundle` dies on
    # "undefined method 'terminate_process' for an instance of
    # Homebrew::InstallSteps::DSL" (zoom, google-chrome, moon, ca-certificates).
    #
    # nix-homebrew bumps brew-src routinely (6.0.9 -> 6.0.11 -> 6.0.12), so this
    # is a gap-filler, not a permanent fork.
    #
    # REMOVE THIS once nix-homebrew pins >= 6.0.13:
    #   drop `inputs.brew-src.follows` above and this input, then `nix:update`.
    brew-src = {
      url = "github:Homebrew/brew/6.0.13";
      flake = false;
    };
    nix-apple-container = {
      url = "github:halfwhey/nix-apple-container";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-shotx = {
      url = "github:aimen08/homebrew-shotx";
      flake = false;
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
      nix-homebrew,
      nix-apple-container,
      homebrew-core,
      homebrew-cask,

      homebrew-shotx,
      ...
    }:
    let
      hostInfo = import ./variables/host-info.nix;
      gitInfo = import ./variables/git-info.nix;
      direnvWhitelist = import ./variables/direnv-whitelist.nix {
        inherit (hostInfo) homedir flakedir;
      };
    in
    {
      # nix-darwin configuration (apply with: darwin-rebuild switch --flake ~/.config/nix)
      darwinConfigurations.${hostInfo.hostname} = nix-darwin.lib.darwinSystem {
        modules = [
          ./configurations/darwin-configuration.nix
          ./configurations/user-darwin-configuration.nix
          mac-app-util.darwinModules.default
          nix-homebrew.darwinModules.nix-homebrew
          nix-apple-container.darwinModules.containerization
        ];
        specialArgs = {
          inherit
            hostInfo
            self
            homebrew-core
            homebrew-cask
            homebrew-shotx
            ;
        };
      };

      # Standalone home-manager configuration (apply with: home-manager switch --flake ~/.config/nix)
      homeConfigurations.${hostInfo.username} = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true;
          overlays = [
            (final: prev: {
              direnv = prev.direnv.overrideAttrs (_: {
                doCheck = false;
              });
            })
          ];
        };
        modules = [
          ./configurations/home-configuration.nix
          ./configurations/user-home-configuration.nix
          mac-app-util.homeManagerModules.default
        ];
        extraSpecialArgs = {
          inherit
            hostInfo
            gitInfo
            direnvWhitelist
            nix-vscode-extensions
            ;
        };
      };
    };
}
