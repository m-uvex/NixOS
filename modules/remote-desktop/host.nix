{ pkgs, lib, ... }:

let
  sunshineVirtualDisplay = pkgs.writeShellScriptBin "sunshine-virtual-display" ''
    set -e

    ACTION="''${1:-start}"

    get_headless_monitor() {
      ${pkgs.hyprland}/bin/hyprctl monitors -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.[].name | select(test("^HEADLESS"))' | head -n 1
    }

    case "$ACTION" in
      start|do)
        # Dynamically read client display specs provided by Sunshine (fallback to 1080p@60)
        CLIENT_W="''${SUNSHINE_CLIENT_WIDTH:-1920}"
        CLIENT_H="''${SUNSHINE_CLIENT_HEIGHT:-1080}"
        CLIENT_FPS="''${SUNSHINE_CLIENT_FPS:-60}"

        echo "[Sunshine Display] Dynamic client request: ''${CLIENT_W}x''${CLIENT_H}@''${CLIENT_FPS}Hz"

        MONITOR=$(get_headless_monitor)
        if [ -z "$MONITOR" ]; then
          echo "[Sunshine Display] Creating headless virtual output in Hyprland..."
          ${pkgs.hyprland}/bin/hyprctl output create headless >/dev/null 2>&1 || true
          sleep 0.5
          MONITOR=$(get_headless_monitor)
        fi

        MONITOR="''${MONITOR:-HEADLESS-1}"
        echo "[Sunshine Display] Applying mode ''${CLIENT_W}x''${CLIENT_H}@''${CLIENT_FPS}Hz to $MONITOR..."
        ${pkgs.hyprland}/bin/hyprctl keyword monitor "$MONITOR,''${CLIENT_W}x''${CLIENT_H}@''${CLIENT_FPS},auto,1"

        echo "$MONITOR" > /tmp/sunshine_active_headless_monitor
        echo "[Sunshine Display] Virtual monitor $MONITOR is active and configured."
        ;;

      stop|undo)
        MONITOR=""
        if [ -f /tmp/sunshine_active_headless_monitor ]; then
          MONITOR=$(cat /tmp/sunshine_active_headless_monitor)
          rm -f /tmp/sunshine_active_headless_monitor
        fi

        if [ -z "$MONITOR" ]; then
          MONITOR=$(get_headless_monitor)
        fi

        if [ -n "$MONITOR" ]; then
          echo "[Sunshine Display] Removing/disabling virtual monitor: $MONITOR"
          ${pkgs.hyprland}/bin/hyprctl output remove "$MONITOR" 2>/dev/null || ${pkgs.hyprland}/bin/hyprctl keyword monitor "$MONITOR,disable" 2>/dev/null || true
        fi
        ;;

      status)
        MONITOR=$(get_headless_monitor)
        if [ -n "$MONITOR" ]; then
          echo "Active headless monitor: $MONITOR"
          ${pkgs.hyprland}/bin/hyprctl monitors -j | ${pkgs.jq}/bin/jq -r ".[] | select(.name == \"$MONITOR\")"
        else
          echo "No headless monitor currently active."
        fi
        ;;

      *)
        echo "Usage: sunshine-virtual-display [start|stop|status]"
        exit 1
        ;;
    esac
  '';
in
{
  # Sunshine streaming host configuration for the main PC (Andromeda)
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    applications = {
      env = {
        PATH = "$(PATH):/run/current-system/sw/bin";
      };
      apps = [
        {
          name = "Desktop";
          image-path = "desktop.png";
          prep-cmd = [
            {
              do = "${sunshineVirtualDisplay}/bin/sunshine-virtual-display start";
              undo = "${sunshineVirtualDisplay}/bin/sunshine-virtual-display stop";
            }
          ];
        }
        {
          name = "Steam Big Picture";
          detached = [ "steam steam://open/bigpicture" ];
          image-path = "steam.png";
          prep-cmd = [
            {
              do = "${sunshineVirtualDisplay}/bin/sunshine-virtual-display start";
              undo = "${sunshineVirtualDisplay}/bin/sunshine-virtual-display stop";
            }
          ];
        }
      ];
    };
  };

  # Wake-on-LAN configuration
  environment.systemPackages = [
    pkgs.ethtool
    sunshineVirtualDisplay
  ];

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="en*", RUN+="${pkgs.ethtool}/bin/ethtool -s %k wol g"
  '';
}
