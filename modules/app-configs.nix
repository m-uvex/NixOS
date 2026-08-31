{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.spacenix;

  appModule = types.submodule ({ name, ... }: {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable SpaceNix configuration management for this app.";
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
        description = "Subdirectory used when layering. Defaults to 'custom' (hypr), 'conf.d' (fish), 'spacenix' (kitty), or profile name.";
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
          echo "[SpaceNix] Overwrite: ${appName} -> $targetDir"
        '' else ''
          targetDir="${if layerSubdir != "" then "$baseTarget/$layerSubdir" else "$baseTarget"}"
          $DRY_RUN_CMD mkdir -p "$targetDir"
          $DRY_RUN_CMD cp -rf "${sourcePath}"/* "$targetDir"/
          $DRY_RUN_CMD chmod -R u+w "$targetDir"
          echo "[SpaceNix] Layer: ${appName} -> $targetDir"
        ''}
        ${appCfg.extraActivation}
      fi
    '';

  enabledApps = filterAttrs (_: app: app.enable) cfg.apps;
  activationScripts = concatStringsSep "\n" (mapAttrsToList buildAppScript enabledApps);

in {
  imports = [
    ./apps
  ];

  options.spacenix = {
    enable = mkEnableOption "SpaceNix modular configuration management";

    configDir = mkOption {
      type = types.path;
      default = ../config;
      description = "Root directory containing modular application configurations.";
    };

    profile = mkOption {
      type = types.str;
      default = "spacenix";
      description = "Active preset/profile subfolder name inside each app's config directory.";
    };

    apps = mkOption {
      type = types.attrsOf appModule;
      default = {};
      description = "Declarative per-application SpaceNix configurations.";
    };
  };

  config = mkIf cfg.enable {
    home.activation.applySpaceNixConfigs = lib.hm.dag.entryAfter [ "copyIllogicalImpulseConfigs" ] ''
      echo "=== Applying SpaceNix Modular Configurations ==="
      ${activationScripts}
    '';
  };
}
