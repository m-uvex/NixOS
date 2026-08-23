{ pkgs, ... }:

{
  # --- DISPLAY & DESKTOP MANAGERS ---
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  programs.hyprland.enable = true;
  programs.driftwm.enable = true;
  programs.dconf.enable = true;

  # --- POLKIT AUTH AGENT ---
  security.polkit.enable = true;
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # --- AUDIO & GRAPHICS LAYER ---
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # --- PORTALS & PACKAGE COMPATIBILITY ---
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk ];
  };

  services.flatpak.enable = true;
  programs.appimage.binfmt = true;

  # --- FONTS ---
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.ubuntu
    noto-fonts-color-emoji
    material-symbols
  ];
}
