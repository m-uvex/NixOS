{ pkgs, inputs, ... }:

{
  # --- ACCOUNTS ---
  users.users."m_uvex" = {
    isNormalUser = true;
    description = "Musa Murad";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    initialPassword = "040810";
  };

  # --- BOOT & NIX SYSTEM SETTINGS ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  nixpkgs.config.allowUnfree = true;

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

  # --- SSH CONFIG ---
  programs.ssh.askPassword = pkgs.lib.mkForce "";
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  users.users."m_uvex".openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKT+rzs85ZnNdaPFsc9FjNFASNYATaXY5qkWQEOJhHfc m_uvex" ];
  programs.ssh.extraConfig = ''
    Host *
      IdentityFile ~/.ssh/m_uvex
  '';
  
  # WoL alias for pc-main-nix (wake-pc)
  environment.shellAliases = {
    wake-pc = "ssh m_uvex@100.78.151.49 'wakeonlan 00:11:22:33:44:55'"; # EDIT MAC ADDRESS ONCE PC BUILT AND READY
  };

  # --- CORE CLI PACKAGES ---
  environment.systemPackages = with pkgs; [
    git
    micro
    bat
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
}
