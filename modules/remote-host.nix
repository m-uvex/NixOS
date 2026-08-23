{ pkgs, ... }:

{
  # Sunshine streaming host configuration for the main PC
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };
  
  # WoL configuration
  environment.systemPackages = [ pkgs.ethtool ];
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="en*", RUN+="${pkgs.ethtool}/bin/ethtool -s %k wol g"
  '';
}

