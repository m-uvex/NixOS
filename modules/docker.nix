{ pkgs, ... }:

{
  # --- DOCKER ENGINE CONFIGURATION ---
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" "--volumes" ];
    };
    daemon.settings = {
      "log-driver" = "json-file";
      "log-opts" = {
        "max-size" = "10m";
        "max-file" = "3";
      };
      "live-restore" = true;
    };
  };

  # Add m_uvex to docker group to run docker CLI without sudo
  users.users.m_uvex.extraGroups = [ "docker" ];

  # Docker CLI & Terminal GUI Utilities
  environment.systemPackages = with pkgs; [
    docker-compose
    lazydocker
    ctop
  ];

  # --- DOCKHAND GUI STACK MANAGER (OCI CONTAINER) ---
  # Automatically starts Dockhand GUI dashboard on port 3000
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      dockhand = {
        image = "fnsys/dockhand:latest";
        autoStart = true;
        ports = [
          "3000:3000"
        ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "/var/lib/dockhand/data:/app/data"
          "/srv/stacks:/app/data/stacks"
          "/srv/stacks:/stacks"
        ];
        environment = {
          TZ = "Europe/Istanbul";
        };
      };
    };
  };
}
