local wezterm = require("wezterm")
local config = wezterm.config_builder()
local target_os = wezterm.target_triple
local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider

-- Helper function to simplify keybinding
local function bind(key, mods, action)
  return { key = key, mods = mods, action = action }
end

local function tab_title(tab_info)
  local title = tab_info.tab_title
  if title and #title > 0 then
    return title
  end

  return tab_info.active_pane.title
end

local scheme_colors = {
  catppuccin = {
    mocha = {
      rosewater = "f5e0dc",
      flamingo = "f2cdcd",
      pink = "f5c2e7",
      mauve = "cba6f7",
      red = "f38ba8",
      maroon = "eba0ac",
      peach = "fab387",
      yellow = "f9e2af",
      green = "a6e3a1",
      teal = "94e2d5",
      sky = "89dceb",
      sapphire = "74c7ec",
      blue = "89b4fa",
      lavender = "b4befe",
      text = "cdd6f4",
      subtext1 = "bac2de",
      subtext0 = "a6adc8",
      overlay2 = "9399b2",
      overlay1 = "7f849c",
      overlay0 = "6c7089",
      surface2 = "585b70",
      surface1 = "45475a",
      surface0 = "313244",
      base = "1e1e2e",
      mantle = " 181825",
      crust = "11111b",
    },
  },
}

local colors = {
  tab_base_color = scheme_colors.catppuccin.mocha.crust,
  hover_tab_bg_color = scheme_colors.catppuccin.mocha.lavender,
  active_tab_bg_color = scheme_colors.catppuccin.mocha.blue,
  active_tab_fg_color = scheme_colors.catppuccin.mocha.crust,
  inactive_tab_bg_color = scheme_colors.catppuccin.mocha.surface0,
  inactive_tab_fg_color = scheme_colors.catppuccin.mocha.text,
}

-- Appearance: Catppuccin Mocha with black background
config.color_scheme = "Catppuccin Mocha"
config.colors = {
  background = "black",
  tab_bar = {
    background = scheme_colors.catppuccin.mocha.crust,
    active_tab = {
      bg_color = colors.active_tab_bg_color,
      fg_color = colors.active_tab_fg_color,
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = colors.inactive_tab_bg_color,
      fg_color = colors.inactive_tab_fg_color,
    },
  },
}

-- Enable and configure the status bar
config.show_new_tab_button_in_tab_bar = false -- Keep tab bar minimal if enabled
config.status_update_interval = 1000          -- Update every second
config.tab_bar_at_bottom = true
-- config.use_fancy_tab_bar = true
config.use_fancy_tab_bar = false

config.font = wezterm.font("JetBrains Mono")
config.font_size = 14

wezterm.on("format-tab-title", function(tab, tabs, panes, window_config, hover, max_width)
  local title = tab_title(tab)
  title = wezterm.truncate_right(title, max_width - 6)
  if tab.is_active then
    return {
      { Background = { Color = colors.tab_base_color } },
      { Foreground = { Color = colors.active_tab_bg_color } },
      { Text = SOLID_LEFT_ARROW },
      { Background = { Color = colors.active_tab_bg_color } },
      { Foreground = { Color = colors.active_tab_fg_color } },
      { Text = " " .. tab.tab_index + 1 .. ":" .. title .. " " },
      { Background = { Color = colors.active_tab_bg_color } },
      { Foreground = { Color = colors.tab_base_color } },
      { Text = SOLID_LEFT_ARROW },
    }
  end

  if hover then
    return {
      { Background = { Color = colors.tab_base_color } },
      { Foreground = { Color = colors.hover_tab_bg_color } },
      { Text = SOLID_LEFT_ARROW },
      { Background = { Color = colors.hover_tab_bg_color } },
      { Foreground = { Color = colors.active_tab_fg_color } },
      { Text = " " .. tab.tab_index + 1 .. ":" .. title .. " " },
      { Background = { Color = colors.hover_tab_bg_color } },
      { Foreground = { Color = colors.tab_base_color } },
      { Text = SOLID_LEFT_ARROW },
    }
  end

  return {
    { Background = { Color = colors.tab_base_color } },
    { Foreground = { Color = colors.inactive_tab_bg_color } },
    { Text = SOLID_LEFT_ARROW },
    { Background = { Color = colors.inactive_tab_bg_color } },
    { Foreground = { Color = colors.inactive_tab_fg_color } },
    { Text = " " .. tab.tab_index + 1 .. ":" .. title .. " " },
    { Background = { Color = colors.inactive_tab_bg_color } },
    { Foreground = { Color = colors.tab_base_color } },
    { Text = SOLID_LEFT_ARROW },
  }
end)

-- config.tab_bar_style = {
-- 	active_tab_right = wezterm.format({
-- 	}),
-- }

-- No minimize/close/expand buttons.

if target_os:match("linux") then
  -- On Linux, use "NONE" to supress all decorations
  config.window_decorations = "NONE"
else
  -- On any other system, use "RESIZE"
  config.window_decorations = "RESIZE"
end

config.window_background_opacity = 0.95     -- Slight transparency for sleek look
config.default_cursor_style = "BlinkingBar" -- Sleek cursor

-- Set PowerShell as the default shell on Windows
if target_os == "x86_64-pc-windows-msvc" then
  config.default_prog = { "powershell.exe", "-NoLogo" }
end

-- Behavior
config.enable_scroll_bar = false -- Minimalist, no scrollbar

-- Tmux-like leader key: CTRL-a
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

-- Tmux-inspired keybindings
config.keys = {
  -- Pane navigation: CTRL-a h/j/k/l (like tmux/vim)
  bind("h", "LEADER", wezterm.action.ActivatePaneDirection("Left")),
  bind("j", "LEADER", wezterm.action.ActivatePaneDirection("Down")),
  bind("k", "LEADER", wezterm.action.ActivatePaneDirection("Up")),
  bind("l", "LEADER", wezterm.action.ActivatePaneDirection("Right")),

  -- Tab management: CTRL-a t (new window)
  bind("t", "LEADER", wezterm.action.SpawnTab("CurrentPaneDomain")),

  -- Close pane: CTRL-a x
  bind("x", "LEADER", wezterm.action.CloseCurrentPane({ confirm = true })),

  -- Send Ctrl-a to terminal if pressed twice (tmux pass-through)
  bind("a", "LEADER", wezterm.action.SendKey({ key = "a", mods = "CTRL" })),
}

for i = 1, 9 do
  table.insert(config.keys, bind(tostring(i), "CTRL", wezterm.action.ActivateTab(i - 1)))
end
return config
