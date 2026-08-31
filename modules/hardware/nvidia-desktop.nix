{ config, lib, pkgs, ... }:

{
  # --- DISCRETE NVIDIA DESKTOP GPU (RTX 50/40/30/20 Series) ---
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Modesetting is required for Wayland / KMS
    modesetting.enable = lib.mkDefault true;

    # Power management for sleep/suspend
    powerManagement.enable = lib.mkDefault true;
    powerManagement.finegrained = lib.mkDefault false;

    # Modern open-source kernel modules (standard for Turing, Ada, Blackwell / RTX 50-series)
    open = lib.mkDefault true;

    # NVIDIA control panel GUI
    nvidiaSettings = lib.mkDefault true;

    # Latest driver release
    package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.latest;
  };

  # Hardware video acceleration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      nvidia-vaapi-driver
    ];
  };

  # Wayland & desktop compositor environment variables
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = lib.mkDefault "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = lib.mkDefault "nvidia";
    NVD_BACKEND = lib.mkDefault "direct";
    ELECTRON_OZONE_PLATFORM_HINT = lib.mkDefault "auto";
  };

  # Early KMS for Wayland compositors
  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
}
