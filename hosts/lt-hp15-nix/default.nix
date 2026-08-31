{ pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core.nix
    ../../modules/desktop.nix
    ../../modules/apps.nix
    ../../modules/gaming.nix
    ../../modules/remote-desktop/client.nix

  ];

  networking.hostName = "lt-hp15-nix";
  system.stateVersion = "24.05";

}
