{ pkgs, inputs, username ? "m_uvex", ... }:

{
  imports = [
    ./hardware/default.nix
    ./rebuild.nix
  ];

  # --- ACCOUNTS ---
  users.users.${username} = {
    isNormalUser = true;
    description = "Musa Murad";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "storage" ];
    hashedPassword = "$6$tFhMrTUbXvCtUK2O$VyQs7xSfEOGBPZlb8UZPOZEA6tr2ZR5ixEvbO1wwhN6iGb3kmgvTCVDbGmAx1u33FSomD4wWIQFw.ly3yGj141";
    openssh.authorizedKeys.keys = [
      # Shared SSH authorized keys for m_uvex across all hosts
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK+Wl/P/x5uB5y442bA5rFw3e1k6FpY2FjYp9/m_uvex m_uvex"
    ];
  };

  # --- SSH SERVER & CLIENT INFRASTRUCTURE ---
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
    openFirewall = true;
  };

  programs.ssh = {
    extraConfig = ''
      Host *
        IdentityFile ~/.ssh/id_ed25519
        IdentityFile ~/.ssh/m_uvex

      Host lunar
        HostName 100.78.151.49
        User ${username}
        ForwardAgent yes

      Host andromeda
        HostName pc-main-nix
        User ${username}
        ForwardAgent yes

      Host orion
        HostName lt-hp15-nix
        User ${username}
        ForwardAgent yes
    '';
  };

  # --- DISK MANAGEMENT & AUTOMOUNT (SERVER + DESKTOP) ---
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  programs.fuse.userAllowOther = true;

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

  # --- NIX HELPER (NH) ---
  programs.nh = {
    enable = true;
    flake = "/etc/nixos";
    clean = {
      enable = true;
      extraArgs = "--keep 5 --keep-since 7d";
    };
  };

  # --- NETWORKING BASE ---
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;
  services.tailscale.enable = true;

  # --- SHELLS ---
  programs.fish.enable = true;

  # WoL alias for pc-main-nix (wake-pc via Lunar)
  environment.shellAliases = {
    wake-pc = "ssh lunar 'wakeonlan 00:11:22:33:44:55'";
  };
}
