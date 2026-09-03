-- OrbitOS
hl.config({
    general = {
        border_size = 0,
        resize_on_border = true,
    },
    decoration = {
        rounding_power = 3,
        blur = {
            enabled = true,
            xray = false,
            special = false,
            new_optimizations = true,
            size = 10,
            passes = 3,
            brightness = 1,
            noise = 0.05,
            contrast = 1,
            vibrancy = 0,
            vibrancy_darkness = 0.5,
            popups = false,
            popups_ignorealpha = 0.6,
        },
        -- Dim
        dim_inactive = true,
        dim_strength = 0.05,
        dim_special = 0.2
    },

    misc = {
        animate_manual_resizes = true,
        animate_mouse_windowdragging = true,
        enable_swallow = true,
        swallow_regex = "(foot|kitty|allacritty|Alacritty)",
    },
})

-- nwg-displays output configuration (monitors & workspaces)
if is_file_exists(HOME .. "/.config/hypr/monitors.lua") then
    dofile(HOME .. "/.config/hypr/monitors.lua")
elseif is_file_exists(HOME .. "/.config/hypr/custom/monitors.lua") then
    dofile(HOME .. "/.config/hypr/custom/monitors.lua")
end

if is_file_exists(HOME .. "/.config/hypr/workspaces.lua") then
    dofile(HOME .. "/.config/hypr/workspaces.lua")
elseif is_file_exists(HOME .. "/.config/hypr/custom/workspaces.lua") then
    dofile(HOME .. "/.config/hypr/custom/workspaces.lua")
end


