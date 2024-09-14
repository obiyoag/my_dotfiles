-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration
local config = wezterm.config_builder()

-- config.font = wezterm.font("MesloLGS Nerd Font Mono", { weight = "Regular" })
config.font_size = 19
config.color_scheme = "Catppuccin Mocha"

config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"
config.show_new_tab_button_in_tab_bar = false
config.window_background_opacity = 0.9
config.adjust_window_size_when_changing_font_size = false
config.window_padding = {
	left = 20,
	right = 20,
	top = 20,
	bottom = 5,
}

config.keys = {
	{
		key = "1",
		mods = "CMD",
		action = wezterm.action.Multiple({
			wezterm.action.SendKey({ mods = "CTRL", key = " " }),
			wezterm.action.SendKey({ key = "1" }),
		}),
	},
	{
		key = "2",
		mods = "CMD",
		action = wezterm.action.Multiple({
			wezterm.action.SendKey({ mods = "CTRL", key = " " }),
			wezterm.action.SendKey({ key = "2" }),
		}),
	},
	{
		key = "3",
		mods = "CMD",
		action = wezterm.action.Multiple({
			wezterm.action.SendKey({ mods = "CTRL", key = " " }),
			wezterm.action.SendKey({ key = "3" }),
		}),
	},
	{
		key = "4",
		mods = "CMD",
		action = wezterm.action.Multiple({
			wezterm.action.SendKey({ mods = "CTRL", key = " " }),
			wezterm.action.SendKey({ key = "4" }),
		}),
	},
	{
		key = "5",
		mods = "CMD",
		action = wezterm.action.Multiple({
			wezterm.action.SendKey({ mods = "CTRL", key = " " }),
			wezterm.action.SendKey({ key = "5" }),
		}),
	},
}

return config
