{ config, pkgs, inputs, ... }:

{
  # --- WALLPAPERS ---
  home.file."Pictures/Wallpapers" = {
    source = ./assets/Wallpapers;
    recursive = true;
  };

  # --- ILLOGICAL-IMPULSE & END4-PC ---
  imports = [
    inputs.illogical-flake.homeManagerModules.default
  ];
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

  # Hyprland configuration for end4-pC
  wayland.windowManager.hyprland.settings = {
    env = [
      "qsConfig,end4-pC"
    ];
    bind = [
      # Global QuickShell shortcut to toggle the end4-pC Settings overlay
      "SUPER, ESCAPE, global, quickshell:settingsToggle"
    ];
  };

  home.stateVersion = "24.05";
}