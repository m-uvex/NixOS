{ pkgs, ... }:

{
  # --- AMDGPU KERNEL MODULE & EARLY KMS ---
  boot.initrd.kernelModules = [ "amdgpu" ];

  # --- AMD GRAPHICS & ROCm COMPUTE ---
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd  # ROCm OpenCL ICD
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      libvdpau-va-gl
    ];
  };

  # Enable full GPU overclocking / undervolting / fan curves via CoreCtrl
  boot.kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];
  programs.corectrl.enable = true;

  # ROCm / HIP symlink for apps requiring standard /opt/rocm path
  systemd.tmpfiles.rules = [
    "L+ /opt/rocm/hip - - - - ${pkgs.rocmPackages.clr}"
  ];

  # GPU monitoring
  environment.systemPackages = with pkgs; [
    radeontop
    clinfo
  ];
}
