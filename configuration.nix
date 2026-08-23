{ config, pkgs, inputs, lib, ... }:

{
  # --- ACCOUNTS ---
  users.users."m_uvex" = {
    isNormalUser = true;
    description = "Musa Murad";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    initialPassword = "040810"; 
  };

  # --- CORE SYSTEM ---
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

  # --- NETWORKING & SECURITY ---
  networking.hostName = "lt-hp15-nix";
  networking.networkmanager.enable = true; 
  networking.firewall.enable = false;
  programs.ssh.askPassword = pkgs.lib.mkForce ""; 

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

  # --- DISPLAY & DESKTOP ENVIRONMENTS ---
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true; 

  programs.driftwm.enable = true;
  programs.hyprland.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  programs.dconf.enable = true;

  # --- HARDWARE, GAMING & MEDIA ---
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

  programs.gamemode.enable = true;
  programs.gamescope.enable = true;
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

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

  # --- THE SOFTWARE STACK ---
  environment.systemPackages = with pkgs; [
    git home-manager kitty bat polkit_gnome 
    wget curl jq socat playerctl libnotify steam-run 
    wl-clipboard grim slurp rofi waybar swww 
    
    micro nautilus mission-center gnome-software
    inputs.nix-software-center.packages.${pkgs.stdenv.hostPlatform.system}.nix-software-center
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    beeper obsidian
    
    krita gimp inkscape obs-studio feishin 
    pear-desktop stremio-linux-shell vacuum-tube
    
    steam heroic vesktop prismlauncher modrinth-app
    mcpelauncher-ui-qt mangohud hydralauncher
    
    vscode python3 nodejs gcc gnumake pkg-config
    opencode opencode-desktop antigravity android-studio
    
    matugen dart-sass gtk4 gtk4-layer-shell glib cairo cliphist
    python3Packages.pygobject3 python3Packages.pycairo
    
    localsend rquickshare tailscale trayscale scrcpy android-tools
    proton-vpn 
  ];

  services.tailscale.enable = true;
  programs.kdeconnect.enable = true;
  system.stateVersion = "24.05";
}
