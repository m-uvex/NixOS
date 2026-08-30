#!/usr/bin/env bash
# ==============================================================================
# cursor-material-set-color.sh — OrbitOS Dynamic Material Cursor Switcher
# Automatically matches Bibata Material cursor variants to wallpaper/Matugen colors
# and applies changes across Hyprland, GNOME, DriftWM, GTK3/4, Qt/KDE, and X11.
# ==============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_JSON="$SCRIPT_DIR/themes.json"
COLOR_MATCH_PY="$SCRIPT_DIR/color_match.py"

CURSOR_SIZE="${BIBATA_CURSOR_SIZE:-24}"
COLORS_JSON="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated/colors.json"
COLOR_TXT="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated/color.txt"

# --- 1. Determine Target Hex Color or Theme Name ---
target_input="${1:-}"

if [[ -n "$target_input" && "$target_input" =~ ^Bibata-Material-(.+)$ ]]; then
    nearest_variant="${BASH_REMATCH[1]}"
elif [[ -n "$target_input" && -f "$THEMES_JSON" ]] && jq -e --arg v "$target_input" 'has($v)' "$THEMES_JSON" >/dev/null 2>&1; then
    nearest_variant="$target_input"
else
    hex_color=""

    if [[ "$target_input" =~ ^#?[A-Fa-f0-9]{6}$ ]]; then
        hex_color="$target_input"
    elif [[ -f "$COLORS_JSON" ]] && command -v jq >/dev/null 2>&1; then
        # Prefer inverse_primary (Tone 80 pastel accent in Material 3) or primary
        hex_color=$(jq -r '.inverse_primary // .primary_fixed_dim // .primary // empty' "$COLORS_JSON" 2>/dev/null || echo "")
    fi

    if [[ -z "$hex_color" && -f "$COLOR_TXT" ]]; then
        hex_color=$(tr -d '[:space:]"' < "$COLOR_TXT")
    fi

    if [[ -z "$hex_color" || ! "$hex_color" =~ ^#?[A-Fa-f0-9]{6}$ ]]; then
        echo "[cursor-material] Notice: No valid color found in state, defaulting to #c7bfff (Lilac)" >&2
        hex_color="#c7bfff"
    fi

    [[ "$hex_color" != \#* ]] && hex_color="#$hex_color"

    # Match to closest theme variant via CIEDE2000
    if [[ -f "$COLOR_MATCH_PY" && -f "$THEMES_JSON" ]]; then
        nearest_variant=$(python3 "$COLOR_MATCH_PY" "$hex_color" "$THEMES_JSON")
    else
        nearest_variant="Lilac"
    fi
fi

THEME_NAME="Bibata-Material-$nearest_variant"
echo "[cursor-material] Applying cursor theme: $THEME_NAME (Size: $CURSOR_SIZE)"

# --- 2. Apply to Hyprland (Live + Session State) ---
if command -v hyprctl >/dev/null 2>&1; then
    if pgrep -x Hyprland >/dev/null 2>&1 || [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
        hyprctl setcursor "$THEME_NAME" "$CURSOR_SIZE" >/dev/null 2>&1 || true
        echo "✓ Updated Hyprland live cursor: $THEME_NAME"
    fi
fi

# Save state for Hyprland session scripts
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated"
echo "$THEME_NAME" > "${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated/cursor_theme.txt"
echo "$CURSOR_SIZE" > "${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated/cursor_size.txt"

# --- 3. Apply to GNOME & GSettings ---
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface cursor-theme "$THEME_NAME" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE" 2>/dev/null || true
    echo "✓ Updated GNOME / gsettings cursor-theme"
fi

if command -v dconf >/dev/null 2>&1; then
    dconf write /org/gnome/desktop/interface/cursor-theme "'$THEME_NAME'" 2>/dev/null || true
    dconf write /org/gnome/desktop/interface/cursor-size "$CURSOR_SIZE" 2>/dev/null || true
fi

# --- 4. Apply to X11, DriftWM & Wayland Default Cursor Fallbacks ---
for default_dir in "$HOME/.icons/default" "$HOME/.local/share/icons/default"; do
    mkdir -p "$default_dir"
    cat <<EOF > "$default_dir/index.theme"
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=$THEME_NAME
EOF
done
echo "✓ Updated ~/.icons/default/index.theme"

# --- 5. Apply to GTK 3 & GTK 4 Configuration ---
update_gtk_settings() {
    local ini_file="$1"
    mkdir -p "$(dirname "$ini_file")"
    if [ ! -f "$ini_file" ]; then
        cat <<EOF > "$ini_file"
[Settings]
gtk-cursor-theme-name=$THEME_NAME
gtk-cursor-theme-size=$CURSOR_SIZE
EOF
    else
        # Update or insert gtk-cursor-theme-name
        if grep -q "gtk-cursor-theme-name" "$ini_file"; then
            sed -i "s/^gtk-cursor-theme-name=.*/gtk-cursor-theme-name=$THEME_NAME/" "$ini_file"
        else
            sed -i "/\[Settings\]/a gtk-cursor-theme-name=$THEME_NAME" "$ini_file"
        fi
        # Update or insert gtk-cursor-theme-size
        if grep -q "gtk-cursor-theme-size" "$ini_file"; then
            sed -i "s/^gtk-cursor-theme-size=.*/gtk-cursor-theme-size=$CURSOR_SIZE/" "$ini_file"
        else
            sed -i "/\[Settings\]/a gtk-cursor-theme-size=$CURSOR_SIZE" "$ini_file"
        fi
    fi
}

update_gtk_settings "$HOME/.config/gtk-3.0/settings.ini"
update_gtk_settings "$HOME/.config/gtk-4.0/settings.ini"

# GTK 2 fallback (if .gtkrc-2.0 is writable or not a read-only symlink)
if [ ! -L "$HOME/.gtkrc-2.0" ] || [ -w "$HOME/.gtkrc-2.0" ]; then
    if [ -f "$HOME/.gtkrc-2.0" ]; then
        sed -i "s/^gtk-cursor-theme-name=.*/gtk-cursor-theme-name=\"$THEME_NAME\"/" "$HOME/.gtkrc-2.0" 2>/dev/null || true
    fi
fi
echo "✓ Updated GTK 3 & GTK 4 settings"

# --- 6. Apply to Xresources / xrdb ---
if [ -f "$HOME/.Xresources" ]; then
    sed -i "s/^Xcursor.theme:.*/Xcursor.theme: $THEME_NAME/" "$HOME/.Xresources" 2>/dev/null || true
    sed -i "s/^Xcursor.size:.*/Xcursor.size: $CURSOR_SIZE/" "$HOME/.Xresources" 2>/dev/null || true
else
    cat <<EOF > "$HOME/.Xresources"
Xcursor.theme: $THEME_NAME
Xcursor.size: $CURSOR_SIZE
EOF
fi

if command -v xrdb >/dev/null 2>&1; then
    xrdb -merge "$HOME/.Xresources" 2>/dev/null || true
fi
echo "✓ Updated Xresources / xrdb"

# --- 7. Apply to Qt / KDE Plasma ---
if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file kdeglobals --group Mouse --key cursorTheme "$THEME_NAME" 2>/dev/null || true
    kwriteconfig6 --file kdeglobals --group Mouse --key cursorSize "$CURSOR_SIZE" 2>/dev/null || true
    kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme "$THEME_NAME" 2>/dev/null || true
    kwriteconfig6 --file kcminputrc --group Mouse --key cursorSize "$CURSOR_SIZE" 2>/dev/null || true
    echo "✓ Updated KDE / Qt globals"
elif command -v kwriteconfig5 >/dev/null 2>&1; then
    kwriteconfig5 --file kdeglobals --group Mouse --key cursorTheme "$THEME_NAME" 2>/dev/null || true
    kwriteconfig5 --file kdeglobals --group Mouse --key cursorSize "$CURSOR_SIZE" 2>/dev/null || true
    kwriteconfig5 --file kcminputrc --group Mouse --key cursorTheme "$THEME_NAME" 2>/dev/null || true
    kwriteconfig5 --file kcminputrc --group Mouse --key cursorSize "$CURSOR_SIZE" 2>/dev/null || true
fi

echo "[cursor-material] Successfully activated $THEME_NAME across all DE/WMs!"
