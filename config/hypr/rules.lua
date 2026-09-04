-- OrbitOS
-- Enable blur for xwayland context menus
hl.window_rule({match = {class = "^()$", title = "^()$" }, no_blur = false })

-- Enable blur for every window
hl.window_rule({match = {class = ".*" }, no_blur = false })

-- Screencast source selector dialog
hl.window_rule({match = {class = "hyprland-share-picker" }, float = true, pin = true, center = true })

