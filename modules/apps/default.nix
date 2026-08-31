{ lib, ... }:

let
  entries = builtins.readDir ./.;
  nixFiles = lib.filterAttrs (name: type:
    type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"
  ) entries;
in
{
  imports = map (name: ./. + "/${name}") (builtins.attrNames nixFiles);
}
