{ pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core.nix
    ../../modules/desktop.nix
    ../../modules/apps.nix
    ../../modules/gaming.nix
    ../../modules/remote-desktop/client.nix
    ../../modules/hardware/intel-cpu.nix
    ../../modules/hardware/intel-integrated.nix
    ../../modules/hardware/nvidia-hybrid.nix
  ];

  networking.hostName = "lt-hp15-nix";
  system.stateVersion = "24.05";
}
