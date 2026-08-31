{ config, lib, pkgs, ... }:

{
  # --- LEGACY NVIDIA GPU (Kepler / Fermi / GeForce 800M / 700 / 600 Series) ---
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = lib.mkDefault true;
    open = false;
    nvidiaSettings = lib.mkDefault true;
    package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.legacy_470;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
