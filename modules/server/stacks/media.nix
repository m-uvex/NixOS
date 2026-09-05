{ ... }:

let
  composeContent = ''
    name: media

    services:
      jellyfin:
        image: jellyfin/jellyfin:latest
        container_name: jellyfin
        restart: unless-stopped
        devices:
          - /dev/dri:/dev/dri
        ports:
          - "8096:8096"
        volumes:
          - /srv/apps/jellyfin:/config
          - /srv/data/media:/media
          - /srv/data/downloads:/downloads
        environment:
          - TZ=Europe/Istanbul
          - JELLYFIN_PublishedServerUrl=http://lunar:8096
        group_add:
          - "1050"

      jellyseerr:
        image: fallenbagel/jellyseerr:latest
        container_name: jellyseerr
        restart: unless-stopped
        ports:
          - "5055:5055"
        volumes:
          - /srv/apps/arr-stack/jellyseerr:/app/config
        environment:
          - TZ=Europe/Istanbul

      radarr:
        image: lscr.io/linuxserver/radarr:latest
        container_name: radarr
        restart: unless-stopped
        ports:
          - "7878:7878"
        volumes:
          - /srv/apps/arr-stack/radarr:/config
          - /srv/data:/data
        environment:
          - PUID=1000
          - PGID=1050
          - UMASK=002
          - TZ=Europe/Istanbul

      sonarr:
        image: lscr.io/linuxserver/sonarr:latest
        container_name: sonarr
        restart: unless-stopped
        ports:
          - "8989:8989"
        volumes:
          - /srv/apps/arr-stack/sonarr:/config
          - /srv/data:/data
        environment:
          - PUID=1000
          - PGID=1050
          - UMASK=002
          - TZ=Europe/Istanbul

      prowlarr:
        image: lscr.io/linuxserver/prowlarr:latest
        container_name: prowlarr
        restart: unless-stopped
        ports:
          - "9696:9696"
        volumes:
          - /srv/apps/arr-stack/prowlarr:/config
        environment:
          - PUID=1000
          - PGID=1050
          - UMASK=002
          - TZ=Europe/Istanbul

      qbittorrent:
        image: lscr.io/linuxserver/qbittorrent:latest
        container_name: qbittorrent
        restart: unless-stopped
        ports:
          - "8080:8080"
          - "6881:6881"
          - "6881:6881/udp"
        volumes:
          - /srv/apps/arr-stack/qbittorrent:/config
          - /srv/data/downloads:/downloads
        environment:
          - PUID=1000
          - PGID=1050
          - UMASK=002
          - TZ=Europe/Istanbul
          - WEBUI_PORT=8080
  '';
in
{
  environment.etc."stacks/media/compose.yaml".text = composeContent;

  systemd.tmpfiles.rules = [
    "d /srv/stacks/media 0755 root root -"
    "C+ /srv/stacks/media/compose.yaml 0644 root root - /etc/stacks/media/compose.yaml"
  ];
}
