{ config, pkgs, inputs, lib, ... }:

{
  # --- WALLPAPERS ---
  home.file."Pictures/Wallpapers" = {
    source = ../../modules/assets/Wallpapers;
    recursive = true;
  };

  # --- ILLOGICAL-IMPULSE & END4-PC ---
  imports = [
    inputs.illogical-flake.homeManagerModules.default
    ../../modules/app-configs.nix
  ];
  programs.illogical-impulse.enable = true;

  # Build end4-pC with dynamic Material cursor integration and compatibility fixes
  xdg.configFile."quickshell/end4-pC".source = pkgs.runCommand "quickshell-end4-pC" { } ''
    cp -r "${inputs.end4-pC}" "$out"
    chmod -R u+w "$out"

    # Fix KeyError on primary_paletteKeyColor in generate_colors_material.py
    if [ -f "$out/scripts/colors/generate_colors_material.py" ]; then
      ${pkgs.gnused}/bin/sed -i "s/material_colors\['primary_paletteKeyColor'\]/material_colors.get('primary_paletteKeyColor', material_colors.get('primary', '#c7bfff'))/g" "$out/scripts/colors/generate_colors_material.py"
    fi

    # Inject dynamic Material cursor switcher into applycolor.sh
    if [ -f "$out/scripts/colors/applycolor.sh" ]; then
      cat << 'EOF' >> "$out/scripts/colors/applycolor.sh"

# Dynamic Material Cursor integration
if [ -x "$HOME/.config/cursor/cursor-material-set-color.sh" ]; then
  "$HOME/.config/cursor/cursor-material-set-color.sh" &
fi
EOF
    fi
  '';

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
    settings = {
      device_config = [
        # Ignore other OS root partition if present
        {
          id_uuid = "7c44d3c0-6394-4479-846a-2815ec797e66";
          ignore = true;
        }
        # Automount all filesystems (removable USBs/drives and internal secondary drives)
        {
          is_filesystem = true;
          ignore = false;
          automount = true;
        }
      ];
    };
  };

  # Ensure udiskie daemon survives compositor restarts and doesn't get blocked
  systemd.user.services.udiskie = {
    Unit = {
      Description = "udiskie mount daemon";
      After = lib.mkForce [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Restart = "always";
      RestartSec = 3;
    };
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
      RemainAfterExit = true;
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
                --daemon
            fi
          done
        fi
      ''}";
      ExecStop = "${pkgs.writeShellScript "rclone-cloud-stop" ''
        RCLONE_CONF="$HOME/.config/rclone/rclone.conf"
        if [ -f "$RCLONE_CONF" ]; then
          REMOTES=$(${pkgs.gnugrep}/bin/grep -E '^\[.*\]$' "$RCLONE_CONF" | ${pkgs.gnused}/bin/sed 's/[\[\]]//g')
          for remote in $REMOTES; do
            MOUNT_DIR="$HOME/Cloud/$remote"
            if ${pkgs.util-linux}/bin/mountpoint -q "$MOUNT_DIR"; then
              /run/wrappers/bin/fusermount -u "$MOUNT_DIR" || true
            fi
          done
        fi
      ''}";
    };
  };

  # --- ANTIGRAVITY IDE CONVERSATION HISTORY PERSISTENCE (LOGIN, SHUTDOWN & 5-MIN TIMER) ---
  systemd.user.services.antigravity-chat-sync = {
    Unit = {
      Description = "Sync Antigravity IDE conversation histories to state.vscdb";
      After = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.writeShellScript "antigravity-sync-start" ''
        /run/current-system/sw/bin/sync-chats || sync-chats || true
      ''}";
      ExecStop = "${pkgs.writeShellScript "antigravity-sync-stop" ''
        /run/current-system/sw/bin/sync-chats || sync-chats || true
      ''}";
    };
  };

  systemd.user.timers.antigravity-chat-sync = {
    Unit = {
      Description = "Periodic sync of Antigravity IDE conversation histories";
    };
    Install = {
      WantedBy = [ "timers.target" "graphical-session.target" ];
    };
    Timer = {
      OnCalendar = "*:0/5";
      Persistent = true;
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

    (pkgs.writeShellScriptBin "automount-storage" ''
      echo "Scanning and automounting all storage devices..."
      ${pkgs.udiskie}/bin/udiskie-mount -a
      echo "Done."
    '')
  ];

  home.stateVersion = "24.05";
}
