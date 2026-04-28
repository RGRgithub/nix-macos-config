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
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
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
      ...
    }:
    let
      hostInfo = import ./variables/host-info.nix;
      gitInfo = import ./variables/git-info.nix;
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
              direnv = prev.direnv.overrideAttrs (_: { doCheck = false; });
            })
          ];
        };
        modules = [
          ./configurations/home-configuration.nix
          ./configurations/user-home-configuration.nix
          mac-app-util.homeManagerModules.default
        ];
        extraSpecialArgs = { inherit hostInfo gitInfo nix-vscode-extensions; };
      };
    };
}
