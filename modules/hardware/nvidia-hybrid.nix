{ config, lib, pkgs, ... }:

{
  # --- NVIDIA HYBRID / OPTIMUS LAPTOP (PRIME OFFLOAD) ---
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = lib.mkDefault true;

    # Dynamic power management: finegrained RTD3 is only supported on Turing and newer (RTX 20xx+), not Pascal (MX150)
    powerManagement.enable = lib.mkDefault true;
    powerManagement.finegrained = lib.mkDefault false;

    # Proprietary modules (required for Pascal MX150 and older mobile GPUs)
    open = lib.mkDefault false;
    nvidiaSettings = lib.mkDefault true;
    # Pascal (MX150, GTX 10xx) and Maxwell are supported up to NVIDIA 580.xx legacy branch (595+ dropped Pascal)
    package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.legacy_580;

    # PRIME Offload configuration
    prime = {
      offload = {
        enable = lib.mkForce true;
        enableOffloadCmd = lib.mkForce true; # Provides `nvidia-offload <app>` command
      };
      sync.enable = lib.mkForce false;
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
    NVD_BACKEND = lib.mkDefault "direct";
    ELECTRON_OZONE_PLATFORM_HINT = lib.mkDefault "auto";
  };
}
