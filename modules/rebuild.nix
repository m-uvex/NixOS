{ pkgs, ... }:

let
  restoreSshScript = pkgs.writeShellScriptBin "restore-ssh" ''
    set -e

    ARCHIVE="''${1:-/etc/nixos/secrets/ssh.tar.age}"
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

    ARCHIVE="''${1:-/etc/nixos/secrets/ssh.tar.age}"
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

SSH Helpers:
  restore-ssh          Decrypt /etc/nixos/secrets/ssh.tar.age into ~/.ssh (interactive passphrase)
  backup-ssh           Encrypt ~/.ssh into /etc/nixos/secrets/ssh.tar.age with a passphrase

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
      echo "==> Updating flake inputs in /etc/nixos..."
      sudo ${pkgs.nix}/bin/nix flake update --flake /etc/nixos
    fi

    echo "==> Building and applying configuration ($ACTION) for: $HOST..."
    ${pkgs.nh}/bin/nh os "$ACTION" /etc/nixos -H "$HOST" "''${EXTRA_ARGS[@]}"

    # Post-build step: Prompt for interactive SSH key restoration if missing on switch/test
    if [ "$ACTION" = "switch" ] || [ "$ACTION" = "test" ]; then
      TARGET_USER="''${SUDO_USER:-$USER}"
      TARGET_HOME=$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6)
      TARGET_HOME="''${TARGET_HOME:-/home/$TARGET_USER}"

      if [ -f /etc/nixos/secrets/ssh.tar.age ]; then
        if [ ! -f "$TARGET_HOME/.ssh/id_ed25519" ] && [ ! -f "$TARGET_HOME/.ssh/m_uvex" ] && [ ! -f "$TARGET_HOME/.ssh/id_rsa" ]; then
          echo ""
          echo "==> No SSH keys detected in $TARGET_HOME/.ssh/"
          echo "==> Found encrypted backup: /etc/nixos/secrets/ssh.tar.age"
          read -p "==> Would you like to restore ~/.ssh now? [Y/n] " -r resp || resp="Y"
          if [[ "$resp" =~ ^([yY][eE][sS]|[yY]|"")$ ]]; then
            ${restoreSshScript}/bin/restore-ssh /etc/nixos/secrets/ssh.tar.age || true
          fi
        fi
      fi
    fi
  '';
in
{
  environment.systemPackages = [
    rebuildScript
    restoreSshScript
    backupSshScript
    pkgs.nh
    pkgs.nvd
    pkgs.age
    pkgs.gnutar
  ];
}
