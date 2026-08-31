{ config, lib, ... }:

{
  spacenix.apps.kitty = {
    enable = lib.mkDefault true;
    mode = lib.mkDefault "layer";
    layerTarget = lib.mkDefault "spacenix";
    extraActivation = ''
      # Ensure include directive is present in main kitty.conf
      mainConf="$baseTarget/kitty.conf"
      if [ -f "$mainConf" ]; then
        if ! grep -q "include ./$layerSubdir/kitty.conf" "$mainConf" && ! grep -q "include $layerSubdir/kitty.conf" "$mainConf"; then
          if [ -z "$DRY_RUN_CMD" ]; then
            printf "\n# SpaceNix overrides\ninclude ./$layerSubdir/kitty.conf\n" >> "$mainConf"
          fi
        fi
      fi
    '';
  };

  # Automatically disable upstream illogical-impulse kitty dotfiles when in overwrite mode
  programs.illogical-impulse.dotfiles.kitty.enable =
    lib.mkDefault (config.spacenix.apps.kitty.enable && config.spacenix.apps.kitty.mode != "overwrite");
}
