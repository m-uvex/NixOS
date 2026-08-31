{ config, lib, pkgs, ... }:

{
  # --- NVIDIA HYBRID / OPTIMUS LAPTOP (PRIME OFFLOAD) ---
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = lib.mkDefault true;

    # Dynamic power management: powers down dGPU when unused
    powerManagement.enable = lib.mkDefault true;
    powerManagement.finegrained = lib.mkDefault true;

    # Proprietary modules (required for Pascal MX150 and older mobile GPUs)
    open = lib.mkDefault false;
    nvidiaSettings = lib.mkDefault true;
    package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.stable;

    # PRIME Offload configuration
    prime = {
      offload = {
        enable = lib.mkDefault true;
        enableOffloadCmd = lib.mkDefault true; # Provides `nvidia-offload <app>` command
      };
      # Sensible default bus IDs (can be customized in hardware-configuration.nix)
      intelBusId = lib.mkDefault "PCI:0:2:0";
      nvidiaBusId = lib.mkDefault "PCI:2:0:0";
    };
  };

  # Hardware acceleration
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

  # Wayland compatibility
  environment.sessionVariables = {
    __GLX_VENDOR_LIBRARY_NAME = lib.mkDefault "nvidia";
    NVD_BACKEND = lib.mkDefault "direct";
    ELECTRON_OZONE_PLATFORM_HINT = lib.mkDefault "auto";
  };
}
