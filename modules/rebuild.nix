{ pkgs, ... }:

let
  restoreSshScript = pkgs.writeShellScriptBin "restore-ssh" ''
    set -e

    ARCHIVE="''${1:-/orbitos/secrets/ssh.tar.age}"
    TARGET_USER="''${SUDO_USER:-$USER}"
    TARGET_HOME=$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6)
    TARGET_HOME="''${TARGET_HOME:-/home/$TARGET_USER}"

    if [ ! -f "$ARCHIVE" ]; then
      echo "error: encrypted SSH archive not found at: $ARCHIVE"
      exit 1
    fi

    echo "==> Restoring SSH keys for $TARGET_USER into $TARGET_HOME/.ssh from $ARCHIVE..."
    mkdir -p "$TARGET_HOME/.ssh"

    if ${pkgs.age}/bin/age -d "$ARCHIVE" | ${pkgs.gnutar}/bin/tar -xz -C "$TARGET_HOME/"; then
      chown -R "$TARGET_USER:users" "$TARGET_HOME/.ssh" 2>/dev/null || true
      chmod 700 "$TARGET_HOME/.ssh"
      chmod 600 "$TARGET_HOME/.ssh"/* 2>/dev/null || true
      chmod 644 "$TARGET_HOME/.ssh"/*.pub 2>/dev/null || true
      echo "==> SSH keys successfully restored to $TARGET_HOME/.ssh/"
    else
      echo "error: decryption failed or incorrect passphrase."
      exit 1
    fi
  '';

  backupSshScript = pkgs.writeShellScriptBin "backup-ssh" ''
    set -e

    ARCHIVE="''${1:-/orbitos/secrets/ssh.tar.age}"
    TARGET_USER="''${SUDO_USER:-$USER}"
    TARGET_HOME=$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6)
    TARGET_HOME="''${TARGET_HOME:-/home/$TARGET_USER}"

    if [ ! -d "$TARGET_HOME/.ssh" ]; then
      echo "error: directory $TARGET_HOME/.ssh does not exist."
      exit 1
    fi

    echo "==> Backing up $TARGET_HOME/.ssh to $ARCHIVE..."
    echo "==> You will be prompted to set an age passphrase:"

    mkdir -p "$(dirname "$ARCHIVE")"
    ${pkgs.gnutar}/bin/tar -cz -C "$TARGET_HOME" .ssh | ${pkgs.age}/bin/age -p -o "$ARCHIVE"
    chmod 644 "$ARCHIVE"
    echo "==> Encrypted SSH archive saved to $ARCHIVE"
  '';

  syncChatsScript = pkgs.writeScriptBin "sync-chats" ''
    #!${pkgs.python3}/bin/python3
    import sqlite3, os, base64, glob, json, time, shutil, uuid

    def parse_proto(b):
        fields = {}
        i = 0
        while i < len(b):
            shift = 0; tag_wire = 0
            while True:
                if i >= len(b): return fields
                byte = b[i]; tag_wire |= (byte & 0x7f) << shift; i += 1
                if not (byte & 0x80): break
                shift += 7
            tag = tag_wire >> 3; wire = tag_wire & 7
            if wire == 0:
                val = 0; shift = 0
                while True:
                    if i >= len(b): return fields
                    byte = b[i]; val |= (byte & 0x7f) << shift; i += 1
                    if not (byte & 0x80): break
                    shift += 7
                fields.setdefault(tag, []).append(("varint", val))
            elif wire == 2:
                l = 0; shift = 0
                while True:
                    if i >= len(b): return fields
                    byte = b[i]; l |= (byte & 0x7f) << shift; i += 1
                    if not (byte & 0x80): break
                    shift += 7
                sub = b[i:i+l]; i += l
                fields.setdefault(tag, []).append(("bytes", sub))
            elif wire == 1:
                val = b[i:i+8]; i += 8
                fields.setdefault(tag, []).append(("64bit", val))
            elif wire == 5:
                val = b[i:i+4]; i += 4
                fields.setdefault(tag, []).append(("32bit", val))
            else:
                break
        return fields

    def encode_varint(val):
        res = bytearray()
        while True:
            b = val & 0x7f
            val >>= 7
            if val:
                res.append(b | 0x80)
            else:
                res.append(b)
                break
        return bytes(res)

    def encode_field(tag, wire_type, data):
        header = encode_varint((tag << 3) | wire_type)
        if wire_type == 0:
            return header + encode_varint(data)
        elif wire_type == 2:
            if isinstance(data, str):
                data = data.encode("utf-8")
            return header + encode_varint(len(data)) + data
        raise NotImplementedError("wire_type")

    def make_timestamp(sec, nano=0):
        return encode_field(1, 0, sec) + encode_field(2, 0, nano)

    def make_ws_info(uri="file:///etc/nixos", repo="m-uvex/NixOS", repo_url="git@github.com:m-uvex/NixOS.git", branch="main"):
        repo_msg = encode_field(1, 2, repo) + encode_field(2, 2, repo_url)
        return (encode_field(1, 2, uri) +
                encode_field(2, 2, uri) +
                encode_field(3, 2, repo_msg) +
                encode_field(4, 2, branch))

    target_user = os.environ.get("SUDO_USER") or os.environ.get("USER") or "m_uvex"
    home_dir = os.path.expanduser("~" + target_user if target_user != os.environ.get("USER") else "~")

    db_path = os.path.join(home_dir, ".config/Antigravity IDE/User/globalStorage/state.vscdb")
    backup_path = os.path.join(home_dir, ".config/Antigravity IDE/User/globalStorage/state.vscdb.backup")
    conv_dir = os.path.join(home_dir, ".gemini/antigravity-ide/conversations")
    brain_dir = os.path.join(home_dir, ".gemini/antigravity-ide/brain")

    if not os.path.exists(conv_dir) or not os.path.exists(db_path):
        exit(0)

    try:
        shutil.copyfile(db_path, backup_path)
    except Exception:
        pass

    top_proto = bytearray()
    dbs = glob.glob(os.path.join(conv_dir, "*.db"))
    count = 0

    for db in sorted(dbs, key=os.path.getmtime, reverse=True):
        cid = os.path.basename(db)[:-3]
        mtime = int(os.path.getmtime(db))

        ws_bytes = None
        created_ts_bytes = None
        session_id = str(uuid.uuid5(uuid.NAMESPACE_DNS, cid))
        uri = "file:///etc/nixos"

        try:
            conn = sqlite3.connect(db)
            c = conn.cursor()
            c.execute("SELECT data FROM trajectory_metadata_blob WHERE id=\"main\"")
            row = c.fetchone()
            if row and row[0]:
                f = parse_proto(row[0])
                if f.get(1): ws_bytes = f[1][0][1]
                if f.get(2): created_ts_bytes = f[2][0][1]
                if f.get(3): session_id = f[3][0][1].decode("utf-8", errors="ignore")
                if f.get(7): uri = f[7][0][1].decode("utf-8", errors="ignore")
            conn.close()
        except Exception:
            pass

        if not ws_bytes:
            ws_bytes = make_ws_info(uri)
        if not created_ts_bytes:
            created_ts_bytes = make_timestamp(mtime)

        title = None
        t_file = os.path.join(brain_dir, cid, ".system_generated", "logs", "transcript.jsonl")
        if os.path.exists(t_file):
            try:
                with open(t_file) as f:
                    for line in f:
                        d = json.loads(line)
                        if d.get("type") == "USER_INPUT":
                            c = d.get("content", "")
                            if "<USER_REQUEST>" in c:
                                req = c.split("<USER_REQUEST>")[1].split("</USER_REQUEST>")[0].strip()
                                title = req.split("\n")[0][:60].strip()
                            else:
                                title = c.strip().split("\n")[0][:60].strip()
                            break
            except Exception:
                pass
        if not title:
            title = f"Conversation {cid[:8]}"

        sub17 = (encode_field(1, 2, ws_bytes) +
                 encode_field(2, 2, created_ts_bytes) +
                 encode_field(3, 2, session_id) +
                 encode_field(6, 2, cid) +
                 encode_field(7, 2, uri))

        modified_ts_bytes = make_timestamp(mtime)
        summary_id = str(uuid.uuid5(uuid.NAMESPACE_OID, cid))

        summary = (encode_field(1, 2, title) +
                   encode_field(2, 0, 207) +
                   encode_field(3, 2, modified_ts_bytes) +
                   encode_field(4, 2, summary_id) +
                   encode_field(5, 0, 1) +
                   encode_field(7, 2, created_ts_bytes) +
                   encode_field(9, 2, ws_bytes) +
                   encode_field(10, 2, modified_ts_bytes) +
                   encode_field(15, 2, bytes()) +
                   encode_field(16, 0, 100) +
                   encode_field(17, 2, sub17) +
                   encode_field(22, 0, 4))

        b64_str = base64.b64encode(summary).decode("utf-8")
        submsg = encode_field(1, 2, b64_str)
        entry = encode_field(1, 2, cid) + encode_field(2, 2, submsg)
        top_proto.extend(encode_field(1, 2, entry))
        count += 1

    encoded_b64 = base64.b64encode(bytes(top_proto)).decode("utf-8")

    try:
        conn = sqlite3.connect(db_path, timeout=10)
        cur = conn.cursor()
        cur.execute("CREATE TABLE IF NOT EXISTS ItemTable (key TEXT PRIMARY KEY, value TEXT)")
        cur.execute("INSERT OR REPLACE INTO ItemTable (key, value) VALUES (\"antigravityUnifiedStateSync.trajectorySummaries\", ?)", (encoded_b64,))
        conn.commit()
        cur.execute("PRAGMA wal_checkpoint(FULL)")
        conn.close()
        print(f"==> Antigravity IDE: Synced {count} conversation histories to state.vscdb")
    except Exception as e:
        print(f"Warning: could not sync Antigravity IDE chat history: {e}")
  '';

  rebuildScript = pkgs.writeShellScriptBin "rebuild" ''
    set -e

    show_help() {
      cat << 'EOF'
OrbitOS Rebuilder

Usage: rebuild [ACTION] [HOST] [update|--update|-u] [OPTIONS...]

Actions:
  switch               Build and activate configuration (default)
  test                 Build and activate without adding to bootloader menu
  boot                 Build and add to bootloader menu without activating now
  build                Build system generation only
  dry, --dry, -d       Show what would change and package diffs without switching
  clean                Garbage collect older generations (nh clean all)
  help, --help, -h     Show this help message

Options:
  [HOST]               Target host (e.g., lt-hp15-nix, pc-main-nix, srv-c4030-nix)
                       Defaults to current machine hostname
  update, --update, -u Update flake inputs before building
  --ask, -a            Prompt for confirmation before switching
  --show-trace         Show detailed Nix stack traces on evaluation error

Helpers:
  sync-chats           Synchronize all local conversation history into Antigravity IDE
  restore-ssh          Decrypt /orbitos/secrets/ssh.tar.age into ~/.ssh (interactive passphrase)
  backup-ssh           Encrypt ~/.ssh into /orbitos/secrets/ssh.tar.age with a passphrase

Examples:
  rebuild                      # Rebuild and switch current host with visual diffs
  rebuild update               # Update flakes and rebuild current host
  rebuild test                 # Test configuration in current session
  rebuild dry                  # Preview package additions/upgrades/diffs
  rebuild pc-main-nix          # Build configuration for 'pc-main-nix'
  rebuild lt-hp15-nix update   # Update flakes and build for 'lt-hp15-nix'
  rebuild clean                # Clean up old system generations
EOF
      exit 0
    }

    ACTION="switch"
    DO_UPDATE=0
    HOST=""
    EXTRA_ARGS=()

    for arg in "$@"; do
      case "$arg" in
        help|--help|-h)
          show_help
          ;;
        switch|test|boot|build)
          ACTION="$arg"
          ;;
        dry|--dry|-d)
          ACTION="switch"
          EXTRA_ARGS+=("--dry")
          ;;
        clean)
          ACTION="clean"
          ;;
        update|--update|-u)
          DO_UPDATE=1
          ;;
        -*)
          EXTRA_ARGS+=("$arg")
          ;;
        *)
          # Check if host matches known naming pattern or is positional host arg
          if [ -z "$HOST" ]; then
            HOST="$arg"
          else
            EXTRA_ARGS+=("$arg")
          fi
          ;;
      esac
    done

    if [ "$ACTION" = "clean" ]; then
      echo "==> Running nh clean all..."
      exec ${pkgs.nh}/bin/nh clean all "''${EXTRA_ARGS[@]}"
    fi

    HOST="''${HOST:-$(hostname)}"

    if [ "$DO_UPDATE" -eq 1 ]; then
      echo "==> Updating flake inputs in /orbitos..."
      sudo ${pkgs.nix}/bin/nix flake update --flake /orbitos
    fi

    # Clean up stale Home Manager .backup files that could block generation activation
    TARGET_USER="''${SUDO_USER:-$USER}"
    TARGET_HOME=$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6)
    TARGET_HOME="''${TARGET_HOME:-/home/$TARGET_USER}"
    rm -f "$TARGET_HOME"/.config/gtk-3.0/*.backup "$TARGET_HOME"/.config/gtk-4.0/*.backup "$TARGET_HOME"/.config/matugen/templates/*/*.backup "$TARGET_HOME"/.config/fish/*.backup 2>/dev/null || true

    echo "==> Building and applying configuration ($ACTION) for: $HOST..."
    ${pkgs.nh}/bin/nh os "$ACTION" /orbitos -H "$HOST" "''${EXTRA_ARGS[@]}"

    # Post-build step: Sync Antigravity IDE chat history
    if [ "$ACTION" = "switch" ] || [ "$ACTION" = "test" ]; then
      ${syncChatsScript}/bin/sync-chats || true

      # Prompt for interactive SSH key restoration if missing on switch/test
      if [ -f /orbitos/secrets/ssh.tar.age ]; then
        if [ ! -f "$TARGET_HOME/.ssh/id_ed25519" ] && [ ! -f "$TARGET_HOME/.ssh/m_uvex" ] && [ ! -f "$TARGET_HOME/.ssh/id_rsa" ]; then
          echo ""
          echo "==> No SSH keys detected in $TARGET_HOME/.ssh/"
          echo "==> Found encrypted backup: /orbitos/secrets/ssh.tar.age"
          read -p "==> Would you like to restore ~/.ssh now? [Y/n] " -r resp || resp="Y"
          if [[ "$resp" =~ ^([yY][eE][sS]|[yY]|"")$ ]]; then
            ${restoreSshScript}/bin/restore-ssh /orbitos/secrets/ssh.tar.age || true
          fi
        fi
      fi

      # Reload Hyprland if running
      if pgrep -x Hyprland >/dev/null 2>&1 || [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
        echo "==> Reloading Hyprland configuration..."
        if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
          TARGET_UID=$(id -u "$SUDO_USER" 2>/dev/null || echo "1000")
          sudo -u "$SUDO_USER" env XDG_RUNTIME_DIR="/run/user/$TARGET_UID" ${pkgs.hyprland}/bin/hyprctl reload >/dev/null 2>&1 || ${pkgs.hyprland}/bin/hyprctl reload >/dev/null 2>&1 || true
        else
          ${pkgs.hyprland}/bin/hyprctl reload >/dev/null 2>&1 || true
        fi
        echo "==> Hyprland reloaded."
      fi
    fi
  '';
in
{
  environment.systemPackages = [
    rebuildScript
    syncChatsScript
    restoreSshScript
    backupSshScript
    pkgs.nh
    pkgs.nvd
    pkgs.age
    pkgs.gnutar
  ];
}
