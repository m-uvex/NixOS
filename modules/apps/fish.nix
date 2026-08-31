{ config, lib, ... }:

{
  spacenix.apps.fish = {
    enable = lib.mkDefault true;
    mode = lib.mkDefault "layer";
    layerTarget = lib.mkDefault "conf.d";
  };

  # Automatically disable upstream illogical-impulse fish dotfiles when in overwrite mode
  programs.illogical-impulse.dotfiles.fish.enable =
    lib.mkDefault (config.spacenix.apps.fish.enable && config.spacenix.apps.fish.mode != "overwrite");
}
