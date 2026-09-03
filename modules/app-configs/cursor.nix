{ config, lib, pkgs, ... }:

{
  orbitos.apps.cursor = {
    enable = true;
    mode = "overwrite";
    source = ../../config/cursor;
    targetDir = "$HOME/.config/cursor";
    extraActivation = ''
      # Ensure scripts in ~/.config/cursor are executable
      chmod +x "$HOME/.config/cursor"/*.sh 2>/dev/null || true
      chmod +x "$HOME/.config/cursor"/*.py 2>/dev/null || true

      # Inject dynamic Material cursor switcher into quickshell/ii colors script if not already present
      II_COLORS_SCRIPT="$HOME/.config/quickshell/ii/scripts/colors/applycolor.sh"
      if [ -f "$II_COLORS_SCRIPT" ] && ! grep -q "cursor-material-set-color.sh" "$II_COLORS_SCRIPT"; then
        cat << 'EOF' >> "$II_COLORS_SCRIPT"

# Dynamic Material Cursor integration
if [ -x "$HOME/.config/cursor/cursor-material-set-color.sh" ]; then
  "$HOME/.config/cursor/cursor-material-set-color.sh" &
fi
EOF
        echo "[OrbitOS] Injected Material Cursor hook into quickshell/ii applycolor.sh"
      fi

      # Inject into quickshell/end4-pC if present and writable
      END4_COLORS_SCRIPT="$HOME/.config/quickshell/end4-pC/scripts/colors/applycolor.sh"
      if [ -f "$END4_COLORS_SCRIPT" ] && [ -w "$END4_COLORS_SCRIPT" ] && ! grep -q "cursor-material-set-color.sh" "$END4_COLORS_SCRIPT"; then
        cat << 'EOF' >> "$END4_COLORS_SCRIPT"

# Dynamic Material Cursor integration
if [ -x "$HOME/.config/cursor/cursor-material-set-color.sh" ]; then
  "$HOME/.config/cursor/cursor-material-set-color.sh" &
fi
EOF
        echo "[OrbitOS] Injected Material Cursor hook into quickshell/end4-pC applycolor.sh"
      fi

      # Ensure quickshell user generated state directory is user-writable
      STATE_GEN_DIR="$HOME/.local/state/quickshell/user/generated"
      if [ -d "$STATE_GEN_DIR" ]; then
        chmod -R u+w "$STATE_GEN_DIR" 2>/dev/null || true
      fi

      # Trigger initial cursor application if desktop is active
      if [ -x "$HOME/.config/cursor/cursor-material-set-color.sh" ]; then
        "$HOME/.config/cursor/cursor-material-set-color.sh" >/dev/null 2>&1 || true
      fi
    '';
  };
}
