{ config, pkgs, inputs, lib, ... }:

{
  # --- WALLPAPERS ---
  home.file."Pictures/Wallpapers" = {
    source = ./assets/Wallpapers;
    recursive = true;
  };

  # --- ILLOGICAL-IMPULSE & END4-PC ---
  imports = [
    inputs.illogical-flake.homeManagerModules.default
  ];
  programs.illogical-impulse = {
    enable = true;
    dotfiles = {
      fish.enable = true;
      kitty.enable = true;
      starship.enable = true;
    };
  };
  xdg.configFile."quickshell/end4-pC".source = inputs.end4-pC;
  home.sessionVariables = {
    qsConfig = "end4-pC";
  };

  home.activation.configureEnd4pC = lib.hm.dag.entryAfter [ "copyIllogicalImpulseConfigs" ] ''
    mkdir -p "$HOME/.config/hypr/custom"

    cat > "$HOME/.config/hypr/custom/variables.lua" << 'EOF'
-- Set active quickshell configuration to end4-pC
hl.env("qsConfig", "end4-pC")
EOF

    cat > "$HOME/.config/hypr/custom/keybinds.lua" << 'EOF'
hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )
hl.bind("SUPER + escape", hl.dsp.global("quickshell:settingsToggle"), {description = "Toggle settings"})
EOF

    chmod -R u+w "$HOME/.config/hypr/custom"
  '';

  home.stateVersion = "24.05";
}
