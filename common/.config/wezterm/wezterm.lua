local wezterm = require("wezterm")
local config = wezterm.config_builder()
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.pl_left_hard_divider
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
  active_tab_bg_color = scheme_colors.catppuccin.mocha.blue,
  active_tab_fg_color = scheme_colors.catppuccin.mocha.crust,
  inactive_tab_bg_color = scheme_colors.catppuccin.mocha.surface0,
  inactive_tab_fg_color = scheme_colors.catppuccin.mocha.text,
}

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
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

wezterm.on("update-right-status", function(window, pane)
  -- Time/Date
  local date = wezterm.strftime("%Y-%m-%d")
  local time = wezterm.strftime("%H:%M:%S")

  -- Assemble like tmux status-right
  local status = wezterm.format({
    { Background = { Color = scheme_colors.catppuccin.mocha.teal } },
    { Foreground = { Color = colors.tab_base_color } },
    { Text = SOLID_RIGHT_ARROW },
    { Background = { Color = scheme_colors.catppuccin.mocha.teal } },
    { Foreground = { Color = scheme_colors.catppuccin.mocha.crust } },
    { Text = " " .. date .. " " },
    { Background = { Color = colors.tab_base_color } },
    { Foreground = { Color = scheme_colors.catppuccin.mocha.teal } },
    { Text = SOLID_RIGHT_ARROW },
    { Background = { Color = scheme_colors.catppuccin.mocha.lavender } },
    { Foreground = { Color = colors.tab_base_color } },
    { Text = SOLID_RIGHT_ARROW },
    { Background = { Color = scheme_colors.catppuccin.mocha.lavender } },
    { Foreground = { Color = scheme_colors.catppuccin.mocha.crust } },
    { Text = " " .. time .. " " },
    { Background = { Color = colors.tab_base_color } },
    { Foreground = { Color = scheme_colors.catppuccin.mocha.lavender } },
    { Text = SOLID_RIGHT_ARROW },
  })

  window:set_right_status(status)
end)

config = {
  window_close_confirmation = "NeverPrompt",

  -- Appearance: Catppuccin Mocha with black background
  color_scheme = "Catppuccin Mocha",
  colors = {
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
  },

  -- Enable and configure the status bar
  show_new_tab_button_in_tab_bar = false, -- Keep tab bar minimal if enabled
  status_update_interval = 1000,          -- Update every second
  tab_bar_at_bottom = true,
  use_fancy_tab_bar = false,

  -- Fonts
  font = wezterm.font("JetBrains Mono"),
  font_size = 14,

  -- No minimize/close/expand buttons.
  -- RESIZE to allow Komorebi to manage the window
  window_decorations = "RESIZE",
  window_background_opacity = 0.95,       -- Slight transparency for sleek look
  default_cursor_style = "BlinkingBlock", -- Sleek cursor

  -- Set PowerShell as the default shell on Windows
  default_prog = wezterm.target_triple:match("windows") and { "powershell.exe", "-NoLogo" } or nil,

  -- Behavior
  enable_scroll_bar = false, -- Minimalist, no scrollbar

  -- Tmux-like leader key: CTRL-a
  leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 },

  -- Tmux-inspired keybindings
  keys = {
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
  },
}

for i = 1, 9 do
  table.insert(config.keys, bind(tostring(i), "CTRL", wezterm.action.ActivateTab(i - 1)))
end

return config
