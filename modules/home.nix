{ config, pkgs, inputs, lib, ... }:

{
  # --- WALLPAPERS ---
  home.file."Pictures/Wallpapers" = {
    source = ./assets/Wallpapers;
    recursive = true;
  };

  # --- ILLOGICAL-IMPULSE & END4-PC ---
  imports = [
    inputs.illogical-flake.homeManagerModules.default
    ./app-configs.nix
  ];
  programs.illogical-impulse.enable = true;
  xdg.configFile."quickshell/end4-pC".source = inputs.end4-pC;
  home.sessionVariables = {
    qsConfig = "end4-pC";
  };

  # --- ORBITOS MODULAR CONFIGURATION MANAGER ---
  orbitos = {
    enable = true;
    profile = "orbitos";
  };

  # --- DESKTOP AUTOMOUNT (USER SESSION) ---
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "auto";
  };

  # --- NETWORK & GVFS AUTOMOUNT SERVICE (PARALLEL MULTI-SHARE & GOOGLE DRIVE LOGIN AUTOMOUNT) ---
  systemd.user.services.gvfs-network-automount = {
    Unit = {
      Description = "Automount all remembered network connections (SMB, SFTP, WebDAV, Google Drive)";
      After = [ "graphical-session.target" "gnome-keyring.service" ];
      Wants = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "gvfs-network-automount" ''
        BOOKMARKS="$HOME/.config/gtk-3.0/bookmarks"
        CUSTOM_LIST="$HOME/.config/gvfs-automount.list"

        mount_uri() {
          local raw="$1"
          local uri
          uri=$(echo "$raw" | awk '{print $1}')
          case "$uri" in
            smb://*|sftp://*|dav://*|davs://*|ftp://*|nfs://*|afp://*|google-drive://*)
              echo "Automounting network/cloud share: $uri"
              ${pkgs.glib}/bin/gio mount "$uri" >/dev/null 2>&1 &
              ;;
          esac
        }

        if [ -f "$BOOKMARKS" ]; then
          while IFS= read -r line || [ -n "$line" ]; do
            mount_uri "$line"
          done < "$BOOKMARKS"
        fi

        if [ -f "$CUSTOM_LIST" ]; then
          while IFS= read -r line || [ -n "$line" ]; do
            mount_uri "$line"
          done < "$CUSTOM_LIST"
        fi

        wait
      ''}";
    };
  };

  # --- RCLONE MULTI-ACCOUNT CLOUD AUTOMOUNT SERVICE (GOOGLE DRIVE, ONEDRIVE, DROPBOX, NEXTCLOUD) ---
  systemd.user.services.rclone-cloud-automount = {
    Unit = {
      Description = "Automount all configured Rclone cloud remotes (Google Drive, OneDrive, etc.)";
      After = [ "graphical-session.target" "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "rclone-cloud-automount" ''
        RCLONE_CONF="$HOME/.config/rclone/rclone.conf"
        if [ -f "$RCLONE_CONF" ]; then
          REMOTES=$(${pkgs.gnugrep}/bin/grep -E '^\[.*\]$' "$RCLONE_CONF" | ${pkgs.gnused}/bin/sed 's/[\[\]]//g')
          for remote in $REMOTES; do
            MOUNT_DIR="$HOME/Cloud/$remote"
            mkdir -p "$MOUNT_DIR"
            if ! ${pkgs.util-linux}/bin/mountpoint -q "$MOUNT_DIR"; then
              echo "Automounting Rclone cloud remote '$remote' to $MOUNT_DIR..."
              ${pkgs.rclone}/bin/rclone mount "$remote:" "$MOUNT_DIR" \
                --vfs-cache-mode full \
                --daemon >/dev/null 2>&1 &
            fi
          done
        fi
        wait
      ''}";
    };
  };

  # Helper CLI commands to trigger network and cloud share automounts manually
  home.packages = [
    (pkgs.writeShellScriptBin "automount-network" ''
      echo "Scanning and automounting remembered network connections..."
      BOOKMARKS="$HOME/.config/gtk-3.0/bookmarks"
      CUSTOM_LIST="$HOME/.config/gvfs-automount.list"

      mount_uri() {
        local raw="$1"
        local uri
        uri=$(echo "$raw" | awk '{print $1}')
        case "$uri" in
          smb://*|sftp://*|dav://*|davs://*|ftp://*|nfs://*|afp://*|google-drive://*)
            echo "-> Automounting: $uri"
            ${pkgs.glib}/bin/gio mount "$uri" &
            ;;
        esac
      }

      if [ -f "$BOOKMARKS" ]; then
        while IFS= read -r line || [ -n "$line" ]; do
          mount_uri "$line"
        done < "$BOOKMARKS"
      fi

      if [ -f "$CUSTOM_LIST" ]; then
        while IFS= read -r line || [ -n "$line" ]; do
          mount_uri "$line"
        done < "$CUSTOM_LIST"
      fi

      wait
      echo "Done."
    '')

    (pkgs.writeShellScriptBin "automount-cloud" ''
      echo "Scanning and automounting all Rclone cloud remotes..."
      RCLONE_CONF="$HOME/.config/rclone/rclone.conf"
      if [ -f "$RCLONE_CONF" ]; then
        REMOTES=$(${pkgs.gnugrep}/bin/grep -E '^\[.*\]$' "$RCLONE_CONF" | ${pkgs.gnused}/bin/sed 's/[\[\]]//g')
        for remote in $REMOTES; do
          MOUNT_DIR="$HOME/Cloud/$remote"
          mkdir -p "$MOUNT_DIR"
          if ! ${pkgs.util-linux}/bin/mountpoint -q "$MOUNT_DIR"; then
            echo "-> Automounting Rclone remote '$remote' -> $MOUNT_DIR"
            ${pkgs.rclone}/bin/rclone mount "$remote:" "$MOUNT_DIR" \
              --vfs-cache-mode full \
              --daemon
          else
            echo "-> Already mounted: $MOUNT_DIR"
          fi
        done
      else
        echo "No rclone config found at ~/.config/rclone/rclone.conf."
        echo "Run 'rclone config' to add your Google Drive or other cloud accounts!"
      fi
      echo "Done."
    '')
  ];

  home.stateVersion = "24.05";
}
