{ ... }:

let
  composeContent = ''
    name: dev

    services:
      pocketbase:
        image: ghcr.io/muchobien/pocketbase:latest
        container_name: pocketbase
        restart: unless-stopped
        ports:
          - "8090:8090"
        volumes:
          - /srv/apps/pocketbase/pb_data:/pb_data
          - /srv/apps/pocketbase/pb_public:/pb_public
        environment:
          - TZ=Europe/Istanbul

      gitea:
        image: gitea/gitea:latest
        container_name: gitea
        restart: unless-stopped
        ports:
          - "3001:3000"
          - "2222:22"
        volumes:
          - /srv/apps/gitea:/data
          - /etc/timezone:/etc/timezone:ro
          - /etc/localtime:/etc/localtime:ro
        environment:
          - USER_UID=1000
          - USER_GID=1000

      it-tools:
        image: corentinth/it-tools:latest
        container_name: it_tools
        restart: unless-stopped
        ports:
          - "8084:80"

      homepage:
        image: ghcr.io/gethomepage/homepage:latest
        container_name: homepage
        restart: unless-stopped
        ports:
          - "8083:3000"
        volumes:
          - /srv/apps/homepage:/app/config
          - /var/run/docker.sock:/var/run/docker.sock:ro
        environment:
          - TZ=Europe/Istanbul

      uptime-kuma:
        image: louislam/uptime-kuma:latest
        container_name: uptime_kuma
        restart: unless-stopped
        ports:
          - "3002:3001"
        volumes:
          - /srv/apps/uptime-kuma:/app/data
        environment:
          - TZ=Europe/Istanbul
  '';
in
{
  environment.etc."stacks/dev/compose.yaml".text = composeContent;

  systemd.tmpfiles.rules = [
    "d /srv/stacks/dev 0755 root root -"
    "d /srv/apps/homepage 0755 root root -"
    "d /srv/apps/uptime-kuma 0755 root root -"
    "d /srv/apps/pocketbase/pb_data 0770 oliver pocketbase -"
    "d /srv/apps/pocketbase/pb_public 0770 oliver pocketbase -"
    "C+ /srv/stacks/dev/compose.yaml 0644 root root - /etc/stacks/dev/compose.yaml"
  ];
}
