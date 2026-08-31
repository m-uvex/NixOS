{ ... }:

{
  imports = [
    ../../modules/core.nix
    ../../modules/docker.nix
    ../../modules/hardware/intel-cpu.nix
    ../../modules/hardware/intel-integrated.nix
    # ./hardware-configuration.nix
  ];

  networking.hostName = "srv-c4030-nix";
  system.stateVersion = "24.05";
}
