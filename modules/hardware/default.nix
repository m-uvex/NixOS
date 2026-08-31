{ pkgs, ... }:

{
  # --- FIRMWARE BASE ---
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;

  # --- GRAPHICS BASE ---
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # --- FIRMWARE UPDATES (LVFS / fwupd) ---
  services.fwupd.enable = true;

  # --- STORAGE & SSD/NVME LIFECYCLE ---
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  services.smartd = {
    enable = true;
    autodetect = true;
  };

  # --- DYNAMIC POWER MANAGEMENT ---
  services.power-profiles-daemon.enable = true;

  # --- BLUETOOTH BASE ---
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };

  # --- INPUT CONTROLLERS & PERIPHERALS ---
  hardware.xone.enable = true;
  hardware.xpadneo.enable = true;
  hardware.opentabletdriver.enable = true;
  services.hardware.openrgb.enable = true;
  services.udev.packages = [ pkgs.dualsensectl ];

  # --- HARDWARE MONITORING & DIAGNOSTIC UTILITIES ---
  environment.systemPackages = with pkgs; [
    nvtopPackages.full
    vulkan-tools
    mesa-demos
    clinfo
    libva-utils
    smartmontools
    nvme-cli
    lm_sensors
    pciutils
    usbutils
    inxi
    fwupd
    dualsensectl
    openrgb
  ];
}
