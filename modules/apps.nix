{ pkgs, inputs, ... }:

{
  programs.kdeconnect.enable = true;

  environment.systemPackages = with pkgs; [
    # Terminal, Bar, & Rice Utilities
    kitty polkit_gnome playerctl libnotify steam-run
    wl-clipboard grim slurp rofi waybar awww cliphist quickshell
    matugen dart-sass gtk4 gtk4-layer-shell glib cairo
    python3Packages.pygobject3 python3Packages.pycairo

    # Productivity, Browsers & Web
    nautilus mission-center gnome-software obsidian
    inputs.nix-software-center.packages.${pkgs.stdenv.hostPlatform.system}.nix-software-center
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    
    # Messengers & Social
    beeper vesktop signal-desktop
    
    # Media & Creative
    krita gimp inkscape
    obs-studio
    feishin pear-desktop
    stremio-linux-shell vacuum-tube

    # Dev & Tools
    jetbrains.idea antigravity antigravity-cli antigravity-ide android-studio
    python3 nodejs gcc gnumake pkg-config
    opencode opencode-desktop

    # Device Sync & Networking UI
    localsend rquickshare
    trayscale proton-vpn
    scrcpy android-tools
  ];
}
