{ config, lib, ... }:

{
  orbitos.apps.nixpkgs = {
    enable = lib.mkDefault true;
    mode = lib.mkDefault "overwrite";
  };
}
