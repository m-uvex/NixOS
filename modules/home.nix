{ config, pkgs, inputs, lib, ... }:

{
  # --- WALLPAPERS ---
  home.file."Pictures/Wallpapers" = {
    source = ./assets/Wallpapers;
    recursive = true;
  };

  # --- ILLOGICAL-IMPULSE & END4-PC ---
  imports = [
    inputs.illogical-flake.homeManagerModules.default
    ./app-configs.nix
  ];
  programs.illogical-impulse.enable = true;
  xdg.configFile."quickshell/end4-pC".source = inputs.end4-pC;
  home.sessionVariables = {
    qsConfig = "end4-pC";
  };

  # --- SPACENIX MODULAR CONFIGURATION MANAGER ---
  spacenix = {
    enable = true;
    profile = "spacenix";
  };

  home.stateVersion = "24.05";
}
