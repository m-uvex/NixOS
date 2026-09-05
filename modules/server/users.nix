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

  # --- RESTRICTED DEV USER: OLIVER ---
  # Oliver has SSH-key only access, no sudo/wheel privileges, and is restricted to the pocketbase group
  users.users.oliver = {
    isNormalUser = true;
    description = "Oliver (Pocketbase Dev)";
    group = "pocketbase";
    extraGroups = [ "pocketbase" ];
    createHome = true;
    home = "/home/oliver";
    openssh.authorizedKeys.keys = [
      # Add Oliver's public SSH key here when available
      # "ssh-ed25519 AAAAC3... oliver"
    ];
  };
}
