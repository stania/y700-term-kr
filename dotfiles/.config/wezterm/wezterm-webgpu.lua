local wezterm = require "wezterm"
local config = wezterm.config_builder()

config.font = wezterm.font_with_fallback({
  "PlemolKRConsole Nerd Font Mono",
  "Noto Sans CJK KR",
})
config.font_size = 14.0
config.dpi = 192.0

-- WebGpu mode: VK_ICD_FILENAMES must be set to SwiftShader or turnip ICD before launching
-- Launch via: VK_ICD_FILENAMES=~/.config/vulkan/icd.d/swiftshader_icd.json wezterm --config-file ~/.config/wezterm/wezterm-webgpu.lua
config.front_end = "WebGpu"
config.enable_wayland = false
config.max_fps = 60
config.cursor_blink_rate = 500

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
