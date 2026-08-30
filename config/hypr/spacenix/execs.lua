-- SpaceNix Custom Hyprland Execs
hl.on("hyprland.start", function ()
    -- Initialize Material cursor based on active wallpaper palette
    hl.exec_cmd("~/.config/quickshell/ii/scripts/colors/cursor/cursor-material-set-color.sh")
end)
