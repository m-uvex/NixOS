{ ... }:

{
  imports = [
    # Temporarily point to laptop hardware for testing:
    ../lt-hp15-nix/hardware-configuration.nix
    ../../modules/hardware/nvidia-hybrid.nix
    ../../modules/hardware/intel-cpu.nix
    # When building on actual PC, swap to: ./hardware-configuration.nix
    
    ../../modules/core.nix
    ../../modules/desktop.nix
    ../../modules/apps.nix
    ../../modules/gaming.nix
    ../../modules/remote-desktop/host.nix
    #../../modules/hardware/amd-cpu.nix
    #../../modules/hardware/nvidia-desktop.nix
  ];

  networking.hostName = "pc-main-nix";
  system.stateVersion = "24.05";
}
