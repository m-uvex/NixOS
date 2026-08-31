{ lib, pkgs, ... }:

{
  # --- INTEL INTEGRATED GRAPHICS (UHD / Iris Xe / HD Graphics) ---
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver  # Modern VA-API (iHD) for Gen 8+
      intel-vaapi-driver  # Legacy VA-API (i965) for Gen 7 and older
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };

  # Set default VA-API driver to modern iHD
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = lib.mkDefault "iHD";
  };
}
