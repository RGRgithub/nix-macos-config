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
      hostInfo = import ./variables/host-info.nix;
      gitInfo = import ./variables/git-info.nix;
    in
    {
      # nix-darwin configuration (apply with: darwin-rebuild switch --flake ~/.config/nix)
      darwinConfigurations.${hostInfo.hostname} = nix-darwin.lib.darwinSystem {
        modules = [
          ./configurations/darwin-configuration.nix
          mac-app-util.darwinModules.default
        ];
        specialArgs = { inherit hostInfo self; };
      };

      # Standalone home-manager configuration (apply with: home-manager switch --flake ~/.config/nix)
      homeConfigurations.${hostInfo.username} = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true;
        };
        modules = [
          ./configurations/home-configuration.nix
          ./configurations/user-configuration.nix
          mac-app-util.homeManagerModules.default
        ];
        extraSpecialArgs = { inherit hostInfo gitInfo nix-vscode-extensions; };
      };
    };
}
