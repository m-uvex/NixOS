{ config, lib, inputs, ... }:

let
  mkGtkTemplate = gtkVer:
    let
      # Upstream Matugen template path from end4-pC or illogical-flake dotfiles
      upstreamPath1 = inputs.end4-pC + "/dots/matugen/templates/${gtkVer}/gtk.css";
      upstreamPath2 = inputs.illogical-flake + "/dotfiles/matugen/templates/${gtkVer}/gtk.css";

      upstreamPath =
        if builtins.pathExists upstreamPath1 then upstreamPath1
        else if builtins.pathExists upstreamPath2 then upstreamPath2
        else upstreamPath1;

      baseTemplate =
        if builtins.pathExists upstreamPath then
          builtins.readFile upstreamPath
        else
          "";

      # OrbitOS custom CSS file paths (checking direct app folder, profile subfolder, and gtk.css)
      customCssPath1 = config.orbitos.configDir + "/${gtkVer}/custom.css";
      customCssPath2 = config.orbitos.configDir + "/${gtkVer}/${config.orbitos.profile}/custom.css";
      customCssPath3 = config.orbitos.configDir + "/${gtkVer}/gtk.css";

      customCssPath =
        if builtins.pathExists customCssPath1 then customCssPath1
        else if config.orbitos.profile != "" && builtins.pathExists customCssPath2 then customCssPath2
        else if builtins.pathExists customCssPath3 then customCssPath3
        else customCssPath1;

      customCss =
        if builtins.pathExists customCssPath then
          "\n\n/* --- OrbitOS Layer: custom.css --- */\n" + builtins.readFile customCssPath
        else
          "";
    in
      baseTemplate + customCss;
in
{
  orbitos.apps."gtk-3.0" = {
    enable = lib.mkDefault true;
    mode = lib.mkDefault "layer";
  };

  orbitos.apps."gtk-4.0" = {
    enable = lib.mkDefault true;
    mode = lib.mkDefault "layer";
  };

  xdg.configFile."matugen/templates/gtk-3.0/gtk.css".text = lib.mkForce (mkGtkTemplate "gtk-3.0");
  xdg.configFile."matugen/templates/gtk-4.0/gtk.css".text = lib.mkForce (mkGtkTemplate "gtk-4.0");
}
