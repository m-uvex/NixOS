{ pkgs, ... }:

{
  # Steam & Optimization
  programs.gamemode.enable = true;
  programs.gamescope.enable = true; 
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };
  
  # Controllers
  hardware.xone.enable = true;
  hardware.xpadneo.enable = true;
  services.udev.packages = [ pkgs.dualsensectl ];

  # Flatpak Apps
  services.flatpak.packages = [
    "com.modrinth.ModrinthApp"
  ];

  environment.systemPackages = with pkgs; [
    
    # Launchers
    steam
    heroic
    hydralauncher

    # Minecraft	
    prismlauncher
    lunar-client
    mcpelauncher-ui-qt
    (writeShellScriptBin "modrinth" ''
      exec flatpak run com.modrinth.ModrinthApp "$@"
    '')
    
    # Misc
    mangohud
    dualsensectl
  ];
}
