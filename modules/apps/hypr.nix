{ config, lib, ... }:

{
  spacenix.apps.hypr = {
    enable = lib.mkDefault true;
    mode = lib.mkDefault "layer";
    layerTarget = lib.mkDefault "custom";
  };
}
