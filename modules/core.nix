{ pkgs, inputs, username ? "m_uvex", ... }:

{
  # --- ACCOUNTS ---
  users.users.${username} = {
    isNormalUser = true;
    description = "Musa Murad";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "storage" ];
    hashedPassword = "$6$tFhMrTUbXvCtUK2O$VyQs7xSfEOGBPZlb8UZPOZEA6tr2ZR5ixEvbO1wwhN6iGb3kmgvTCVDbGmAx1u33FSomD4wWIQFw.ly3yGj141";
  };

  # --- DISK MANAGEMENT & AUTOMOUNT (SERVER + DESKTOP) ---
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.devmon.enable = true;

  # Allow wheel group users and automount services to mount/eject disks without password prompts
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if ((action.id == "org.freedesktop.udisks2.filesystem-mount" ||
           action.id == "org.freedesktop.udisks2.filesystem-mount-system" ||
           action.id == "org.freedesktop.udisks2.filesystem-mount-other-seat" ||
           action.id == "org.freedesktop.udisks2.encrypted-unlock" ||
           action.id == "org.freedesktop.udisks2.eject-media" ||
           action.id == "org.freedesktop.udisks2.power-off-drive") &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  # --- FILESYSTEM DRIVERS & CORE CLI PACKAGES ---
  programs.nix-ld.enable = true;
  environment.systemPackages = with pkgs; [
    # Automount & Filesystem support
    udiskie
    ntfs3g
    exfatprogs
    dosfstools
    cifs-utils
    sshfs
    davfs2
    rclone

    # CLI tools
    git
    micro
    zoxide
    fastfetch
    bat
    age
    trashy
    btop
    fd
    home-manager
    wget
    curl
    jq
    socat
    tailscale
    wakeonlan

    # Rebuild helper script
    (writeShellScriptBin "rebuild" ''
      HOST="''${1:-$(hostname)}"
      exec sudo nixos-rebuild switch --flake "/etc/nixos#$HOST" "''${@:2}"
    '')
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

  # --- SHELLS ---
  programs.fish.enable = true;

  # WoL alias for pc-main-nix (wake-pc)
  environment.shellAliases = {
    wake-pc = "ssh m_uvex@100.78.151.49 'wakeonlan 00:11:22:33:44:55'";
  };
}
