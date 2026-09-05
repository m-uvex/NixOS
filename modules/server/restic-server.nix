{ pkgs, lib, ... }:

{
  # --- RESTIC REST BACKUP SERVER ---
  # Listens on port 8000 with append-only mode for immutable Prism Launcher backups
  services.restic.server = {
    enable = true;
    listenAddress = "0.0.0.0:8000";
    dataDir = "/srv/data/backups/restic";
    appendOnly = true;
    privateRepos = false;
  };

  networking.firewall.allowedTCPPorts = [ 8000 ];
}
