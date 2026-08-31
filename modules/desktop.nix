{ pkgs, ... }:

let
  bibata-material-cursors = pkgs.stdenvNoCC.mkDerivation {
    pname = "bibata-material-cursors";
    version = "1.0.0";

    src = pkgs.fetchurl {
      url = "https://github.com/SakibShahariar/material-bibata-cursor/releases/download/v1.0.0/bibata-material-v1.0.0.tar.gz";
      hash = "sha256-oNf/+xff0yko4P9H99eq+PDqx91sD9LHZ/CekQJWJTI=";
    };

    sourceRoot = "bibata-material-v1.0.0";

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/icons
      cp -r Bibata-Material-* $out/share/icons/
      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Material Design Bibata Cursor Theme Collection (28 variants)";
      homepage = "https://github.com/SakibShahariar/material-bibata-cursor";
      license = licenses.gpl3;
      platforms = platforms.linux;
    };
  };
in
{
  # --- DISPLAY & DESKTOP MANAGERS ---
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  programs.hyprland.enable = true;
  programs.driftwm.enable = true;
  programs.dconf.enable = true;
  environment.systemPackages = [
    pkgs.nwg-displays
    pkgs.wlr-randr
    bibata-material-cursors
  ];

  # --- DESKTOP SERVICES & INTEGRATIONS ---
  services.geoclue2.enable = true;
  services.upower.enable = true;
  services.gvfs.enable = true;
  services.gnome.gnome-keyring.enable = true;
  services.gnome.gnome-online-accounts.enable = true;
  programs.seahorse.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

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
    rubik
    nerd-fonts.jetbrains-mono
    nerd-fonts.ubuntu
    noto-fonts-color-emoji
    material-symbols
  ];
}