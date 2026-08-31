{ config, pkgs, ... }:

{
  imports = [
    # Temporarily point to laptop hardware for testing:
    ../lt-hp15-nix/hardware-configuration.nix
    # When building on actual PC, swap to: ./hardware-configuration.nix
    
    ../../modules/core.nix
    ../../modules/desktop.nix
    ../../modules/apps.nix
    ../../modules/gaming.nix
    ../../modules/remote-desktop/host.nix
  ];

  networking.hostName = "pc-main-nix";
  system.stateVersion = "24.05";

  # NVIDIA 50-series drivers
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };
}
