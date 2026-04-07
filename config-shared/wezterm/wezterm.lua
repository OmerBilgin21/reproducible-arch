local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.enable_wayland = false
config.font = wezterm.font("CaskaydiaMono Nerd Font Mono")
config.font_size = 16

local theme_file = dofile(os.getenv("HOME") .. "/.config/themedir/current/theme/wezterm.lua")

if theme_file ~= nil then
  config.color_scheme = theme_file["color_scheme"]
else
  local tokyo = wezterm.color.get_builtin_schemes()["Tokyo Night"]

  local function dim(c)
    return wezterm.color.parse(c):darken(0.15)
  end

  tokyo.foreground = dim(tokyo.foreground)
  for i, c in ipairs(tokyo.ansi) do
    tokyo.ansi[i] = dim(c)
  end
  for i, c in ipairs(tokyo.brights) do
    tokyo.brights[i] = dim(c)
  end

  config.color_schemes = { ["Tokyo Night Soft"] = tokyo }
  config.color_scheme = "Tokyo Night Soft"
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

return config
