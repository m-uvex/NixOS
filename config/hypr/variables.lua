-- OrbitOS
-- Set active quickshell configuration to end4-pC
hl.env("qsConfig", "end4-pC")

-- Apps
terminal = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'kitty -1' 'foot' 'alacritty' 'wezterm' 'konsole' 'kgx' 'uxterm' 'xterm'"
fileManager = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'nautilus' 'dolphin' 'nemo' 'thunar' 'kitty -1 fish -c yazi'"
browser = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'zen-browser' 'google-chrome-stable' 'firefox' 'brave' 'chromium' 'microsoft-edge-stable' 'opera' 'librewolf'"
codeEditor = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'idea' 'antigravity' 'windsurf' 'code' 'codium' 'cursor' 'zed' 'zedit' 'zeditor' 'kate' 'gnome-text-editor' 'emacs' 'command -v nvim && kitty -1 nvim' 'command -v micro && kitty -1 micro'"
officeSoftware = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'wps' 'onlyoffice-desktopeditors' 'libreoffice'"
textEditor = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'gnome-text-editor' 'kate' 'emacs'"
volumeMixer = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'pavucontrol-qt' 'pavucontrol'"
settingsApp = "XDG_CURRENT_DESKTOP=gnome ~/.config/hypr/hyprland/scripts/launch_first_available.sh 'qs -p ~/.config/quickshell/$qsConfig/settings.qml' 'systemsettings' 'gnome-control-center' 'better-control'"
taskManager = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'missioncenter' 'gnome-system-monitor' 'plasma-systemmonitor --page-name Processes' 'command -v btop && kitty -1 fish -c btop'"
