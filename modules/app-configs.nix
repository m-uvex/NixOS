{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.orbitos;

  appModule = types.submodule ({ name, ... }: {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable OrbitOS configuration management for this app.";
      };

      mode = mkOption {
        type = types.enum [ "layer" "overwrite" ];
        default = "layer";
        description = ''
          Strategy for deploying this app's configuration:
          - "layer": Drops custom overrides on top of upstream / base configs (e.g. hypr/custom, fish/conf.d, kitty includes).
          - "overwrite": Completely replaces upstream configs with standalone files from this repository.
        '';
      };

      source = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to the custom config folder. Defaults to ../config/<appName>/<profile>.";
      };

      targetDir = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Override base target directory in ~/.config/. Defaults to ~/.config/<appName>.";
      };

      layerTarget = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Subdirectory used when layering. Defaults to 'custom' (hypr), 'conf.d' (fish), 'orbitos' (kitty), or profile name.";
      };

      extraActivation = mkOption {
        type = types.lines;
        default = "";
        description = "Custom post-copy bash commands for this application.";
      };
    };
  });

  # Build bash activation snippets for each enabled application
  buildAppScript = appName: appCfg:
    let
      profilePath = cfg.configDir + "/${appName}/${cfg.profile}";
      directPath = cfg.configDir + "/${appName}";
      sourcePath =
        if appCfg.source != null then appCfg.source
        else if cfg.profile != "" && builtins.pathExists profilePath then profilePath
        else directPath;
      baseTarget = if appCfg.targetDir != null then appCfg.targetDir else "$HOME/.config/${appName}";
      
      # Determine default layer directory per application
      defaultLayerSubdir = cfg.profile;
        
      layerSubdir = if appCfg.layerTarget != null then appCfg.layerTarget else defaultLayerSubdir;
    in
    ''
      # --- App: ${appName} (Mode: ${appCfg.mode}) ---
      if [ -d "${sourcePath}" ]; then
        baseTarget="${baseTarget}"
        layerSubdir="${layerSubdir}"
        ${if appCfg.mode == "overwrite" then ''
          targetDir="$baseTarget"
          $DRY_RUN_CMD mkdir -p "$targetDir"
          
          # Clean up any existing symlinks or files that match source files to prevent write collisions
          for srcFile in "${sourcePath}"/*; do
            if [ -e "$srcFile" ]; then
              baseName=$(basename "$srcFile")
              if [ -L "$targetDir/$baseName" ] || [ -f "$targetDir/$baseName" ]; then
                $DRY_RUN_CMD rm -f "$targetDir/$baseName"
              fi
            fi
          done
          
          $DRY_RUN_CMD cp -rf "${sourcePath}"/* "$targetDir"/
          $DRY_RUN_CMD chmod -R u+w "$targetDir"
          echo "[OrbitOS] Overwrite: ${appName} -> $targetDir"
        '' else ''
          targetDir="${if layerSubdir != "" then "$baseTarget/$layerSubdir" else "$baseTarget"}"
          $DRY_RUN_CMD mkdir -p "$targetDir"
          $DRY_RUN_CMD cp -rf "${sourcePath}"/* "$targetDir"/
          $DRY_RUN_CMD chmod -R u+w "$targetDir"
          echo "[OrbitOS] Layer: ${appName} -> $targetDir"
        ''}
        ${appCfg.extraActivation}
      fi
    '';

  enabledApps = filterAttrs (_: app: app.enable) cfg.apps;
  activationScripts = concatStringsSep "\n" (mapAttrsToList buildAppScript enabledApps);

in {
  imports = [
    ./app-configs
  ];

  options.orbitos = {
    enable = mkEnableOption "OrbitOS modular configuration management";

    configDir = mkOption {
      type = types.path;
      default = ../config;
      description = "Root directory containing modular application configurations.";
    };

    profile = mkOption {
      type = types.str;
      default = "orbitos";
      description = "Active preset/profile subfolder name inside each app's config directory.";
    };

    apps = mkOption {
      type = types.attrsOf appModule;
      default = {};
      description = "Declarative per-application OrbitOS configurations.";
    };
  };

  config = mkIf cfg.enable {
    # 1. Preserve dynamic runtime configs (e.g. nwg-displays outputs) before illogical-impulse wipes ~/.config/hypr
    home.activation.backupOrbitOSDynamicConfigs = lib.hm.dag.entryBefore [ "copyIllogicalImpulseConfigs" ] ''
      PRESERVE_DIR="$HOME/.local/state/orbitos/preserved"
      mkdir -p "$PRESERVE_DIR/hypr"
      
      if [ -f "$HOME/.config/hypr/monitors.conf" ]; then
        cp -f "$HOME/.config/hypr/monitors.conf" "$PRESERVE_DIR/hypr/"
      fi
      if [ -f "$HOME/.config/hypr/monitors.lua" ]; then
        cp -f "$HOME/.config/hypr/monitors.lua" "$PRESERVE_DIR/hypr/"
      fi
      if [ -f "$HOME/.config/hypr/workspaces.conf" ]; then
        cp -f "$HOME/.config/hypr/workspaces.conf" "$PRESERVE_DIR/hypr/"
      fi
      if [ -f "$HOME/.config/hypr/workspaces.lua" ]; then
        cp -f "$HOME/.config/hypr/workspaces.lua" "$PRESERVE_DIR/hypr/"
      fi
    '';

    # 2. Restore preserved dynamic configs and apply OrbitOS layered/overwrite modular configurations
    home.activation.applyOrbitOSConfigs = lib.hm.dag.entryAfter [ "copyIllogicalImpulseConfigs" ] ''
      echo "=== Applying OrbitOS Modular Configurations ==="
      
      # Restore preserved dynamic runtime configs (e.g. nwg-displays outputs)
      PRESERVE_DIR="$HOME/.local/state/orbitos/preserved"
      if [ -d "$PRESERVE_DIR/hypr" ]; then
        for f in "$PRESERVE_DIR/hypr"/*; do
          if [ -f "$f" ]; then
            baseName=$(basename "$f")
            mkdir -p "$HOME/.config/hypr"
            cp -f "$f" "$HOME/.config/hypr/$baseName"
            chmod u+w "$HOME/.config/hypr/$baseName"
            echo "[OrbitOS] Restored preserved dynamic config: ~/.config/hypr/$baseName"
          fi
        done
      fi

      ${activationScripts}
    '';
  };
}
