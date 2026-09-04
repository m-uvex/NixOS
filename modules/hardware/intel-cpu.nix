{ config, lib, ... }:

{
  # --- INTEL CPU MICROCODE ---
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # --- INTEL VIRTUALIZATION ---
  boot.kernelModules = [ "kvm-intel" ];

  # --- THERMAL THROTTLING MANAGEMENT ---
  # thermald requires DPTF/PSVT ACPI tables which are missing/unsupported on many laptops (e.g. HP 15)
  services.thermald.enable = lib.mkDefault false;
}
