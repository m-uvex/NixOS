{ config, lib, ... }:

{
  orbitos.apps.fish = {
    enable = lib.mkDefault true;
    mode = lib.mkDefault "layer";
    layerTarget = lib.mkDefault "conf.d";
  };

  # Automatically disable upstream illogical-impulse fish dotfiles when in overwrite mode
  programs.illogical-impulse.dotfiles.fish.enable =
    lib.mkDefault (config.orbitos.apps.fish.enable && config.orbitos.apps.fish.mode != "overwrite");
}
