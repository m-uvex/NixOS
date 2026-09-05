{ pkgs, ... }:

{
  # --- /srv FILESYSTEM DIRECTORY STRUCTURE & PERMISSIONS ---
  # Enforce the Lunar /srv hierarchy declaratively on boot
  systemd.tmpfiles.rules = [
    # Top-level /srv directories
    "d /srv 0755 root root -"
    "d /srv/stacks 0755 root root -"
    "d /srv/data 0755 root root -"
    "d /srv/apps 0755 root root -"
    "d /srv/infra 0750 root root -"

    # /srv/data: User data & media with setgid media group (2775)
    "d /srv/data/media 2775 root media -"
    "d /srv/data/media/movies 2775 root media -"
    "d /srv/data/media/shows 2775 root media -"
    "d /srv/data/media/music 2775 root media -"
    "d /srv/data/downloads 2775 root media -"
    "d /srv/data/pydio_workspaces 0770 root media -"
    "d /srv/data/backups 0755 root root -"
    "d /srv/data/backups/restic 0750 restic restic -"

    # /srv/apps: Application state and database directories
    "d /srv/apps/immich 0755 root root -"
    "d /srv/apps/jellyfin 0775 root media -"
    "d /srv/apps/pydio 0755 root root -"
    "d /srv/apps/arr-stack 0775 root media -"
    "d /srv/apps/gitea 0755 root root -"
    "d /srv/apps/hoarder 0755 root root -"
    "d /srv/apps/pocketbase 0770 oliver pocketbase -"

    # /srv/infra: Core networking, identity, and security tools
    "d /srv/infra/lldap 0750 root root -"
    "d /srv/infra/authelia 0750 root root -"
    "d /srv/infra/vaultwarden 0750 root root -"
    "d /srv/infra/nginx 0755 root root -"
    "d /srv/infra/pihole 0755 root root -"
    "d /srv/infra/redis 0750 root root -"

    # Dockhand persistent state directory
    "d /var/lib/dockhand 0755 root root -"
    "d /var/lib/dockhand/data 0755 root root -"
  ];
}
