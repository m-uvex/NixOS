{ pkgs, inputs, ... }:

{
  # --- ACCOUNTS ---
  users.users."m_uvex" = {
    isNormalUser = true;
    description = "Musa Murad";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "storage" ];
    hashedPassword = "$6$tFhMrTUbXvCtUK2O$VyQs7xSfEOGBPZlb8UZPOZEA6tr2ZR5ixEvbO1wwhN6iGb3kmgvTCVDbGmAx1u33FSomD4wWIQFw.ly3yGj141";
  };

  # --- DISK MANAGEMENT & AUTOMOUNT (SERVER + DESKTOP) ---
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # Headless automount daemon running at boot for all hosts
  systemd.services.udiskie-automount = {
    description = "Headless Removable Disk Automounter";
    wantedBy = [ "multi-user.target" ];
    after = [ "udisks2.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.udiskie}/bin/udiskie --automount --no-tray --no-notify";
      Restart = "always";
      RestartSec = 5;
      User = "m_uvex";
    };
  };

  # --- FILESYSTEM DRIVERS & CORE CLI PACKAGES ---
  environment.systemPackages = with pkgs; [
    # Automount & Filesystem support
    udiskie
    ntfs3g
    exfatprogs
    dosfstools

    # CLI tools
    git
    micro
    bat
    age
    trashy
    btop
    fd
    sl
    home-manager
    wget
    curl
    jq
    socat
    tailscale
    wakeonlan
  ];

  # --- BOOT & NIX SYSTEM SETTINGS ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (final: prev: {
      gnome-icon-theme = final.adwaita-icon-theme;
    })
  ];

  time.timeZone = "Europe/Istanbul";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  system.autoUpgrade.enable = true;
  system.autoUpgrade.dates = "daily";
  system.autoUpgrade.flake = inputs.self.outPath;
  nix.settings.auto-optimise-store = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # --- NETWORKING BASE ---
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;
  services.tailscale.enable = true;

  # WoL alias for pc-main-nix (wake-pc)
  environment.shellAliases = {
    wake-pc = "ssh m_uvex@100.78.151.49 'wakeonlan 00:11:22:33:44:55'";
  };
}
