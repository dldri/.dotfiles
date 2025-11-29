local wezterm = require("wezterm")
local config = wezterm.config_builder()
local TERMINAL = wezterm.nerdfonts.oct_terminal
local CIRCLE_LEFT_HALF = wezterm.nerdfonts.ple_left_half_circle_thick
local CIRCLE_RIGHT_HALF = wezterm.nerdfonts.ple_right_half_circle_thick
local CALENDAR_CLOCK = wezterm.nerdfonts.md_calendar_clock
local FOLDER = wezterm.nerdfonts.fa_folder_open
local BOLT = wezterm.nerdfonts.fa_bolt

-- Helper function to simplify keybinding
local function bind(key, mods, action)
  return { key = key, mods = mods, action = action }
end

local function basename(s)
  return string.gsub(s, "(.*[/\\])(.*)", "%2")
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

local function set_status(tbl, bg, fg, text)
  table.insert(tbl, { Background = { Color = bg } })
  table.insert(tbl, { Foreground = { Color = fg } })
  table.insert(tbl, { Text = text })
end

wezterm.on("update-status", function(window, pane)
  local left_status = {}
  local tty_name = pane:get_tty_name() or "Windows"

  set_status(
    left_status,
    scheme_colors.catppuccin.mocha.crust,
    scheme_colors.catppuccin.mocha.green,
    " " .. CIRCLE_LEFT_HALF
  )
  set_status(left_status, scheme_colors.catppuccin.mocha.green, scheme_colors.catppuccin.mocha.crust, TERMINAL .. " ")
  set_status(
    left_status,
    scheme_colors.catppuccin.mocha.surface0,
    scheme_colors.catppuccin.mocha.text,
    " " .. tty_name
  )
  set_status(
    left_status,
    scheme_colors.catppuccin.mocha.crust,
    scheme_colors.catppuccin.mocha.surface0,
    CIRCLE_RIGHT_HALF .. " "
  )

  window:set_left_status(wezterm.format(left_status))
end)

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local max_len = 9
  local pane = tab.active_pane

  local process_name = "?"
  local process_info = pane.foreground_process_name:gsub(".exe$", "")
  process_name = basename(process_info)
  if #process_name > max_len then
    process_name = process_name:sub(1, max_len - 1) .. ".."
  end
  local tab_index = tab.tab_index + 1

  local active_tabs = {}
  local inactive_tabs = {}
  if tab.is_active then
    set_status(
      active_tabs,
      scheme_colors.catppuccin.mocha.crust,
      scheme_colors.catppuccin.mocha.surface0,
      " " .. CIRCLE_LEFT_HALF
    )
    set_status(
      active_tabs,
      scheme_colors.catppuccin.mocha.surface0,
      scheme_colors.catppuccin.mocha.text,
      process_name .. " "
    )
    set_status(
      active_tabs,
      scheme_colors.catppuccin.mocha.blue,
      scheme_colors.catppuccin.mocha.crust,
      " " .. tab_index
    )
    set_status(
      active_tabs,
      scheme_colors.catppuccin.mocha.crust,
      scheme_colors.catppuccin.mocha.blue,
      CIRCLE_RIGHT_HALF
    )
    return active_tabs
  end
  set_status(
    inactive_tabs,
    scheme_colors.catppuccin.mocha.crust,
    scheme_colors.catppuccin.mocha.surface0,
    " " .. CIRCLE_LEFT_HALF
  )
  set_status(
    inactive_tabs,
    scheme_colors.catppuccin.mocha.surface0,
    scheme_colors.catppuccin.mocha.text,
    process_name .. " "
  )
  set_status(
    inactive_tabs,
    scheme_colors.catppuccin.mocha.overlay0,
    scheme_colors.catppuccin.mocha.text,
    " " .. tab_index
  )
  set_status(
    inactive_tabs,
    scheme_colors.catppuccin.mocha.crust,
    scheme_colors.catppuccin.mocha.overlay0,
    CIRCLE_RIGHT_HALF
  )
  return inactive_tabs
end)

wezterm.on("update-right-status", function(window, pane)
  -- Time/Date
  local date = wezterm.strftime("%Y-%m-%d")
  local time = wezterm.strftime("%H:%M:%S")

  -- Current dir
  local cwd = pane:get_current_working_dir()
  local full_path = cwd.path:gsub("/$", "")
  local folder_name = basename(full_path)

  local status = {}

  -- Assemble like tmux status-right
  if window:leader_is_active() then
    set_status(status, scheme_colors.catppuccin.mocha.crust, scheme_colors.catppuccin.mocha.teal, CIRCLE_LEFT_HALF)
    set_status(status, scheme_colors.catppuccin.mocha.teal, scheme_colors.catppuccin.mocha.crust, BOLT)
    set_status(
      status,
      scheme_colors.catppuccin.mocha.crust,
      scheme_colors.catppuccin.mocha.teal,
      CIRCLE_RIGHT_HALF .. " "
    )
  end
  set_status(status, scheme_colors.catppuccin.mocha.crust, scheme_colors.catppuccin.mocha.peach, CIRCLE_LEFT_HALF)
  set_status(status, scheme_colors.catppuccin.mocha.peach, scheme_colors.catppuccin.mocha.crust, FOLDER .. " ")
  set_status(status, scheme_colors.catppuccin.mocha.surface0, scheme_colors.catppuccin.mocha.text, " ../" .. folder_name)
  set_status(
    status,
    scheme_colors.catppuccin.mocha.crust,
    scheme_colors.catppuccin.mocha.surface0,
    CIRCLE_RIGHT_HALF .. " "
  )
  set_status(status, scheme_colors.catppuccin.mocha.crust, scheme_colors.catppuccin.mocha.lavender, CIRCLE_LEFT_HALF)
  set_status(
    status,
    scheme_colors.catppuccin.mocha.lavender,
    scheme_colors.catppuccin.mocha.crust,
    CALENDAR_CLOCK .. " "
  )
  set_status(
    status,
    scheme_colors.catppuccin.mocha.surface0,
    scheme_colors.catppuccin.mocha.text,
    " " .. date .. " " .. time
  )
  set_status(
    status,
    scheme_colors.catppuccin.mocha.crust,
    scheme_colors.catppuccin.mocha.surface0,
    CIRCLE_RIGHT_HALF .. " "
  )

  window:set_right_status(wezterm.format(status))
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
