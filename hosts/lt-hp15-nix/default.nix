{ pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core.nix
    ../../modules/desktop.nix
    ../../modules/apps.nix
    ../../modules/gaming.nix
    ../../modules/hardware/intel-cpu.nix
    ../../modules/hardware/intel-integrated.nix
    ../../modules/hardware/nvidia-hybrid.nix
  ];

  networking.hostName = "lt-hp15-nix";
  system.stateVersion = "24.05";

  environment.systemPackages = [ pkgs.moonlight-qt ];

  # Boot-menu profile: wakes PC and launches Moonlight
  specialisation."remote-kiosk".configuration = {
    services.xserver.displayManager.gdm.enable = lib.mkForce false;
    services.xserver.desktopManager.gnome.enable = lib.mkForce false;
    programs.hyprland.enable = lib.mkForce false;

    services.cage = {
      enable = true;
      user = "m_uvex";
      program = "${pkgs.writeShellScript "kiosk-session" ''
        (sleep 2 && ${pkgs.openssh}/bin/ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no m_uvex@100.78.151.49 "${pkgs.wakeonlan}/bin/wakeonlan 00:11:22:33:44:55" || true) &
        exec ${pkgs.moonlight-qt}/bin/moonlight
      ''}";
    };
  };
}
