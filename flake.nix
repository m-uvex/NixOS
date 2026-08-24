{
  description = "Multi-host NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Custom Software
    zen-browser.url = "github:youwen5/zen-browser-flake";
    nix-software-center.url = "github:snowfallorg/nix-software-center";
    driftwm.url = "github:malbiruk/driftwm";

    # illogical-impulse & end4-pC UI Profiles
    illogical-flake = {
      url = "github:soymou/illogical-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    end4-pC = {
      url = "github:pctrade/end4-pC";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, driftwm, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    specialArgs = { inherit inputs; };

    homeManagerModule = {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = specialArgs;
    };
  in {

    nixosConfigurations = {
      #=========================================#
      #                 Orion                   #
      #           Laptop: HP 15, NixOS          #
      #=========================================#
      lt-hp15-nix = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          driftwm.nixosModules.default
          home-manager.nixosModules.home-manager
          homeManagerModule
          ./hosts/lt-hp15-nix/default.nix
        ];
      };

      #=========================================#
      #               Andromeda                 #
      #   PC: Main (RTX5050, R5 5600), NixOS    #
      #=========================================#
      pc-main-nix = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          driftwm.nixosModules.default
          home-manager.nixosModules.home-manager
          homeManagerModule
          ./hosts/pc-main-nix/default.nix
        ];
      };

      #=========================================#
      #                 Lunar                   #
      #   Server: Lenovo AIO C40-30, NixOS      #
      #=========================================#
      srv-c4030-nix = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          ./hosts/srv-c4030-nix/default.nix
        ];
      };
    };
  };
}