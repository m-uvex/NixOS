{ ... }:

{
  imports = [
    # Temporarily point to laptop hardware for testing:
    ../lt-hp15-nix/hardware-configuration.nix
    # When building on actual server, swap to: ./hardware-configuration.nix

    ../../modules/core.nix
    ../../modules/docker.nix
    ../../modules/hardware/intel-cpu.nix
    ../../modules/hardware/intel-integrated.nix
  ];

  networking.hostName = "srv-c4030-nix";
  system.stateVersion = "24.05";
}
