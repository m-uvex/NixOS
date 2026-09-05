{ pkgs, ... }:

{
  # --- SERVER GROUPS ---
  users.groups.media = { };
  users.groups.pocketbase = { };

  # --- ADMIN USER PERMISSIONS ---
  users.users.m_uvex.extraGroups = [
    "media"
    "pocketbase"
    "docker"
    "storage"
    "video"
    "render"
  ];
}
