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
    };
  });

  # Build bash activation snippets for each enabled application
  buildAppScript = appName: appCfg:
    let
      sourcePath = if appCfg.source != null then appCfg.source else (cfg.configDir + "/${appName}/${cfg.profile}");
      baseTarget = if appCfg.targetDir != null then appCfg.targetDir else "$HOME/.config/${appName}";
      
      # Determine default layer directory per application
      defaultLayerSubdir = 
        if appName == "hypr" then "custom"
        else if appName == "fish" then "conf.d"
        else if appName == "kitty" then "spacenix"
        else cfg.profile;
        
      layerSubdir = if appCfg.layerTarget != null then appCfg.layerTarget else defaultLayerSubdir;
    in
    ''
      # --- App: ${appName} (Mode: ${appCfg.mode}) ---
      if [ -d "${sourcePath}" ]; then
        ${if appCfg.mode == "overwrite" then ''
          targetDir="${baseTarget}"
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
          ${if appName == "kitty" then ''
            targetDir="${baseTarget}/${layerSubdir}"
            $DRY_RUN_CMD mkdir -p "$targetDir"
            $DRY_RUN_CMD cp -rf "${sourcePath}"/* "$targetDir"/
            $DRY_RUN_CMD chmod -R u+w "$targetDir"
            
            # Ensure include directive is present in main kitty.conf
            mainConf="${baseTarget}/kitty.conf"
            if [ -f "$mainConf" ]; then
              if ! grep -q "include ./${layerSubdir}/kitty.conf" "$mainConf" && ! grep -q "include ${layerSubdir}/kitty.conf" "$mainConf"; then
                if [ -z "$DRY_RUN_CMD" ]; then
                  printf "\n# SpaceNix overrides\ninclude ./${layerSubdir}/kitty.conf\n" >> "$mainConf"
                fi
              fi
            fi
            echo "[SpaceNix] Layer: kitty -> $targetDir (included in kitty.conf)"
          '' else ''
            targetDir="${baseTarget}/${layerSubdir}"
            $DRY_RUN_CMD mkdir -p "$targetDir"
            $DRY_RUN_CMD cp -rf "${sourcePath}"/* "$targetDir"/
            $DRY_RUN_CMD chmod -R u+w "$targetDir"
            echo "[SpaceNix] Layer: ${appName} -> $targetDir"
          ''}
        ''}
      fi
    '';

  enabledApps = filterAttrs (_: app: app.enable) cfg.apps;
  activationScripts = concatStringsSep "\n" (mapAttrsToList buildAppScript enabledApps);

in {
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
    # Automatically disable upstream illogical-impulse modules when in overwrite mode
    programs.illogical-impulse.dotfiles = {
      fish.enable = mkDefault (if (cfg.apps ? fish && cfg.apps.fish.enable && cfg.apps.fish.mode == "overwrite") then false else true);
      kitty.enable = mkDefault (if (cfg.apps ? kitty && cfg.apps.kitty.enable && cfg.apps.kitty.mode == "overwrite") then false else true);
      starship.enable = mkDefault (if (cfg.apps ? starship && cfg.apps.starship.enable && cfg.apps.starship.mode == "overwrite") then false else true);
    };

    home.activation.applySpaceNixConfigs = lib.hm.dag.entryAfter [ "copyIllogicalImpulseConfigs" ] ''
      echo "=== Applying SpaceNix Modular Configurations ==="
      ${activationScripts}
    '';
  };
}
