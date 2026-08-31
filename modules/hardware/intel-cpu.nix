{ config, lib, ... }:

{
  # --- INTEL CPU MICROCODE ---
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # --- INTEL VIRTUALIZATION ---
  boot.kernelModules = [ "kvm-intel" ];

  # --- THERMAL THROTTLING MANAGEMENT ---
  services.thermald.enable = lib.mkDefault true;
}
