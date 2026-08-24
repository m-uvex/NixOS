{
  description = "Multi-host NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Custom Software
    zen-browser.url = "github:youwen5/zen-browser-flake";
    nix-software-center.url = "github:snowfallorg/nix-software-center";
    driftwm.url = "github:malbiruk/driftwm";
  };

  outputs = { self, nixpkgs, driftwm, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    specialArgs = { inherit inputs; };
  in {


    nixosConfigurations = {
      #=========================================#
      #                  Orion                  #
      #          Laptop: HP 15, NixOS           #
      #=========================================#
      lt-hp15-nix = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          driftwm.nixosModules.default
          ./hosts/lt-hp15-nix/default.nix
        ];
      };

      #=========================================#
      #                Andromeda                #
      #   PC: Main (RTX5050, R5 5600), NixOS    #
      #=========================================#
      pc-main-nix = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          driftwm.nixosModules.default
          ./hosts/pc-main-nix/default.nix
        ];
      };

      #=========================================#
      #                  Lunar                  #
      #    Server: Lenovo AIO C40-30, NixOS     #
      #=========================================#
      srv-c4030-nix = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          ./hosts/srv-c4030-nix/default.nix
        ];
      };
    };

    homeConfigurations = {
      #=========================================#
      #             Caelestia Shell             #
      #=========================================#
      caelestia = mkRice {
        extraModules = [
          inputs.caelestia-shell.homeManagerModules.default
        ];
        extraHyprlandConfig = ''
          exec-once = caelestia
        '';
      };

      #=========================================#
      #             Midnight Shell              #
      #=========================================#
      midnight = mkRice {
        extraModules = [
          inputs.midnight-shell.homeManagerModules.default
        ];
        extraHyprlandConfig = ''
          exec-once = midnight
        '';
      };

      #=========================================#
      #           DankMaterialShell             #
      #=========================================#
      dms = mkRice {
        extraModules = [
          inputs.dms.homeManagerModules.default
        ];
        extraHyprlandConfig = ''
          exec-once = dms
        '';
      };
    };
  };
}
