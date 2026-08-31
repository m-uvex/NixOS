{ config, lib, ... }:

{
  # --- AMD CPU MICROCODE ---
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # --- AMD VIRTUALIZATION & SENSORS ---
  boot.kernelModules = [ "kvm-amd" "zenpower" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.zenpower ];

  # --- AMD P-STATE EPP DRIVER ---
  boot.kernelParams = [ "amd_pstate=active" ];
}
