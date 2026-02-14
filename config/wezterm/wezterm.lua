local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.enable_wayland = false
config.font = wezterm.font("CaskaydiaMono Nerd Font Mono")
config.font_size = 16

local theme_file = dofile(os.getenv("HOME") .. "/.config/themedir/current/theme/wezterm.lua")

if theme_file ~= nil then
	config.color_scheme = theme_file["color_scheme"]
end

config.enable_tab_bar = false
config.window_decorations = "RESIZE"
config.front_end = "OpenGL"
config.window_background_opacity = 0.9
config.hide_mouse_cursor_when_typing = true
config.window_close_confirmation = "NeverPrompt"

config.keys = {
	{ key = "Enter", mods = "SHIFT", action = wezterm.action({ SendString = "\x1b\r" }) },
}

print("config: ", config)

return config
