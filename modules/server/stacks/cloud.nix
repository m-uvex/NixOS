{ ... }:

let
  composeContent = ''
    name: cloud

    services:
      vaultwarden:
        image: vaultwarden/server:latest
        container_name: vaultwarden
        restart: unless-stopped
        ports:
          - "8085:80"
        volumes:
          - /srv/infra/vaultwarden:/data
        environment:
          - TZ=Europe/Istanbul
          - SIGNUPS_ALLOWED=false

      pydio-cells:
        image: pydio/cells:latest
        container_name: pydio-cells
        restart: unless-stopped
        ports:
          - "8082:8080"
        volumes:
          - /srv/apps/pydio/data:/var/cells/data
          - /srv/data/pydio_workspaces:/var/cells/data/workspaces
        environment:
          - CELLS_BIND=0.0.0.0:8080
          - CELLS_EXTERNAL=http://lunar:8082

      immich-server:
        image: ghcr.io/immich-app/immich-server:release
        container_name: immich_server
        restart: unless-stopped
        devices:
          - /dev/dri:/dev/dri
        ports:
          - "2283:2283"
        volumes:
          - /srv/apps/immich/upload:/usr/src/app/upload
          - /srv/data/media/photos:/usr/src/app/upload/library
          - /etc/localtime:/etc/localtime:ro
        environment:
          - TZ=Europe/Istanbul
          - DB_HOSTNAME=immich-postgres
          - DB_USERNAME=postgres
          - DB_DATABASE_NAME=immich
          - REDIS_HOSTNAME=immich-redis
        depends_on:
          - immich-redis
          - immich-postgres

      immich-machine-learning:
        image: ghcr.io/immich-app/immich-machine-learning:release
        container_name: immich_machine_learning
        restart: unless-stopped
        devices:
          - /dev/dri:/dev/dri
        volumes:
          - /srv/apps/immich/model-cache:/cache
        environment:
          - TZ=Europe/Istanbul

      immich-redis:
        image: redis:alpine
        container_name: immich_redis
        restart: unless-stopped

      immich-postgres:
        image: tensorchord/pgvecto-rs:pg14-v0.2.0
        container_name: immich_postgres
        restart: unless-stopped
        environment:
          - POSTGRES_PASSWORD=immichpassword
          - POSTGRES_USER=postgres
          - POSTGRES_DB=immich
        volumes:
          - /srv/apps/immich/postgres:/var/lib/postgresql/data

      hoarder-web:
        image: ghcr.io/hoarder-app/hoarder:latest
        container_name: hoarder_web
        restart: unless-stopped
        ports:
          - "3030:3000"
        volumes:
          - /srv/apps/hoarder/data:/data
        environment:
          - TZ=Europe/Istanbul
          - MEILI_ADDR=http://hoarder-meilisearch:7700
          - BROWSER_WEB_URL=http://hoarder-chrome:9222
        depends_on:
          - hoarder-meilisearch
          - hoarder-chrome

      hoarder-meilisearch:
        image: getmeili/meilisearch:v1.6
        container_name: hoarder_meilisearch
        restart: unless-stopped
        volumes:
          - /srv/apps/hoarder/meili_data:/meili_data
        environment:
          - MEILI_NO_ANALYTICS=true

      hoarder-chrome:
        image: gcr.io/zenika-hub/alpine-chrome:123
        container_name: hoarder_chrome
        restart: unless-stopped
        command:
          - --no-sandbox
          - --disable-gpu
          - --disable-dev-shm-usage
          - --remote-debugging-address=0.0.0.0
          - --remote-debugging-port=9222
  '';
in
{
  environment.etc."stacks/cloud/compose.yaml".text = composeContent;

  systemd.tmpfiles.rules = [
    "d /srv/stacks/cloud 0755 root root -"
    "C+ /srv/stacks/cloud/compose.yaml 0644 root root - /etc/stacks/cloud/compose.yaml"
  ];
}
