{
  description = "MyNix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Custom Software
    zen-browser.url = "github:youwen5/zen-browser-flake";
    nix-software-center.url = "github:snowfallorg/nix-software-center";

    # DEs / WMs
    driftwm.url = "github:malbiruk/driftwm";
    
    # Rices
    midnight-shell.url = "github:dim-ghub/midnight-shell";
    caelestia-shell.url = "github:caelestia-dots/shell";
    dms.url = "github:AvengeMedia/DankMaterialShell";
  };

  outputs = { self, nixpkgs, home-manager, driftwm, ... }@inputs:
  let
    system = "x86_64-linux";
  in {
    nixosConfigurations.lt-hp15-nix = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        driftwm.nixosModules.default

        ./hardware-configuration.nix
        ./configuration.nix
      ];
    };
  };
}
