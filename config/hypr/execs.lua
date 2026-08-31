-- SpaceNix
hl.on("hyprland.start", function ()
    -- Export environment to systemd and DBus
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DISPLAY XDG_SESSION_TYPE XDG_SESSION_DESKTOP QT_QPA_PLATFORMTHEME")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DISPLAY XDG_SESSION_TYPE XDG_SESSION_DESKTOP QT_QPA_PLATFORMTHEME")

    -- Start graphical session target so xdg-desktop-portal and portals activate cleanly
    hl.exec_cmd("systemctl --user start nixos-fake-graphical-session.target")
    hl.exec_cmd("systemctl --user restart xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-desktop-portal")

    -- Initialize Material cursor based on active wallpaper palette
    hl.exec_cmd("~/.config/quickshell/ii/scripts/colors/cursor/cursor-material-set-color.sh")
end)
