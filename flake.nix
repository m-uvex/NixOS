{
  description = "Multi-host NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Custom Software
    zen-browser.url = "github:youwen5/zen-browser-flake";
    nix-software-center.url = "github:snowfallorg/nix-software-center";
    driftwm.url = "github:malbiruk/driftwm";

    # Illogical Impulse & end4-pC
    illogical-flake = {
      url = "github:soymou/illogical-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    end4-pC = {
      url = "github:pctrade/end4-pC";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, driftwm, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    specialArgs = { inherit inputs; };
  in {

    nixosConfigurations = {
      #=========================================#
      #                 Orion                   #
      #         Laptop: HP 15, NixOS            #
      #=========================================#
      lt-hp15-nix = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          driftwm.nixosModules.default
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

      #=========================================#
      #              end4-pC Shell              #
      #=========================================#
      end4-pc = mkRice {
        extraModules = [
          inputs.illogical-flake.homeManagerModules.default
          {
            # Enable the base illogical-impulse framework
            programs.illogical-impulse = {
              enable = true;
              dotfiles = {
                fish.enable = true;
                kitty.enable = true;
                starship.enable = true;
              };
            };
            xdg.configFile."quickshell/end4-pC".source = inputs.end4-pC;
            home.sessionVariables = {
              qsConfig = "end4-pC";
            };
          }
        ];
        extraHyprlandConfig = ''
          # Ensure Hyprland injects the profile variable and binds the settings menu
          env = qsConfig,end4-pC
          bind = SUPER, ESCAPE, global, quickshell:settingsToggle
        '';
      };
    };
  };
}