{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../users/m_uvex
    ../../users/oliver
    ../../modules/core.nix
    ../../modules/server/default.nix
    ../../modules/docker.nix
    ../../modules/hardware/intel-cpu.nix
    ../../modules/hardware/intel-integrated.nix
  ];

  networking.hostName = "srv-c4030-nix";
  system.stateVersion = "24.05";

  # --- BTRFS AUTOMATED SCRUB & UTILITIES ---
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  environment.systemPackages = with pkgs; [
    btrfs-progs
    compsize
  ];
}
