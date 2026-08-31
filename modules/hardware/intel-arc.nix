{ lib, pkgs, ... }:

{
  # --- INTEL ARC & HIGH-PERFORMANCE Xe GRAPHICS ---
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver     # VA-API (iHD)
      vpl-gpu-rt             # Intel OneVPL / Quick Sync Video (QSV) runtime
      intel-compute-runtime  # OpenCL & Level Zero runtime
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-media-driver
      libvdpau-va-gl
    ];
  };

  # Set default VA-API driver to modern iHD
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = lib.mkDefault "iHD";
  };

  # Enable GuC/HuC firmware for Intel Arc GPUs
  boot.kernelParams = [ "i915.enable_guc=3" ];

  # Intel GPU monitoring tools
  environment.systemPackages = [ pkgs.intel-gpu-tools ];
}
