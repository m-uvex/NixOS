{
  description = "Multi-host NixOS configuration";

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
    pkgs = nixpkgs.legacyPackages.${system};
    specialArgs = { inherit inputs; };

    # Standalone Home Manager helper
    mkRice = extraModules: home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit inputs; };
      modules = [
        {
          home.username = "m_uvex";
          home.homeDirectory = "/home/m_uvex";
          home.stateVersion = "24.05";
        }
      ] ++ extraModules;
    };
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
      caelestia = mkRice [
        inputs.caelestia-shell.homeManagerModules.default
      ];

      #=========================================#
      #             Midnight Shell              #
      #=========================================#
      midnight = mkRice [
        inputs.midnight-shell.homeManagerModules.default
      ];

      #=========================================#
      #           DankMaterialShell             #
      #=========================================#
      dms = mkRice [
        inputs.dms.homeManagerModules.default
      ];
    };
  };
}