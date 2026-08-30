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
  # Configure any app to either "layer" (extend upstream) or "overwrite" (fully replace)
  spacenix = {
    enable = true;
    profile = "spacenix";

    apps = {
      # Hyprland: Layers custom lua scripts into ~/.config/hypr/custom/
      hypr.mode = "layer";

      # Kitty: Layers custom overrides into ~/.config/kitty/spacenix/ and includes in kitty.conf
      kitty.mode = "layer";

      # Fish: Overwrites ~/.config/fish with standalone clean end-4 configs
      fish.mode = "overwrite";

      # GTK 3 & GTK 4: Layers custom window translucency CSS into Matugen templates
      "gtk-3.0".mode = "layer";
      "gtk-4.0".mode = "layer";
    };
  };

  home.stateVersion = "24.05";
}
