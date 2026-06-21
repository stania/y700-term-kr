local wezterm = require "wezterm"
local config = wezterm.config_builder()

config.font = wezterm.font_with_fallback({
  "PlemolKRConsole Nerd Font Mono",
  "Noto Sans CJK KR",
  "Noto Sans Symbols 2",
  "Noto Color Emoji",
  "Symbols Nerd Font Mono",
})
config.font_size = 24.0

config.front_end = "Software"
config.enable_wayland = false
config.max_fps = 60
config.cursor_blink_rate = 500

config.use_fancy_tab_bar = false
config.tab_max_width = 32
config.hide_tab_bar_if_only_one_tab = true

config.use_ime = true
config.color_scheme = "nord"
config.window_background_opacity = 0.95

config.keys = {
  {
    key = "Return",
    mods = "SHIFT",
    action = wezterm.action.SendString("\x1b[13;2u"),
  },
}

return config
