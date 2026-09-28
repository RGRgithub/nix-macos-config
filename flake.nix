{
  description = "My system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
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
      # System config (dr:switch)
      darwinConfigurations.${hostInfo.hostname} = nix-darwin.lib.darwinSystem {
        modules = [
          ./configurations/darwin-configuration.nix
          ./configurations/user-darwin-configuration.nix
          mac-app-util.darwinModules.default
          nix-homebrew.darwinModules.nix-homebrew
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

      # Standalone home-manager config (hm:switch)
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
