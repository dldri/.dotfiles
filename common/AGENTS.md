# Common Configuration - Agent Context

## Purpose

The `common/` directory contains cross-platform configuration files that should be symlinked to `$HOME/.config/` on **any** operating system (Linux, Windows, macOS). These are user-facing application configs that are platform-agnostic.

---

## Directory Structure

```
common/
└── .config/
    ├── nvim/              # Neovim text editor (Lua config)
    ├── wezterm/
    │   └── wezterm.lua   # Wezterm terminal emulator
    ├── starship.toml     # Shell prompt configuration
    └── yazi/             # Yazi file manager
        ├── init.lua
        ├── theme.toml
        └── yazi.toml
```

All files in `common/.config/` are intended to be stowed directly to `$HOME/.config/` using GNU Stow.

---

## Stow Behavior

- **Target**: `$HOME/.config/`
- **Command**: `stow -t $HOME common`
- **Effect**: Creates symlinks from `common/.config/*` to `$HOME/.config/*`
- **Idempotent**: Safe to run multiple times; will overwrite existing symlinks or skip unchanged files

---

## Dependencies

These tools must be installed for the configs to function:

| Application | Package (Linux) | Package (Windows) | Minimum Version |
|-------------|-----------------|-------------------|-----------------|
| Neovim | `neovim` (AUR) | `neovim` (Chocolatey) | 0.8+ (LuaJIT) |
| Wezterm | `wezterm` (AUR) | `wezterm` (Chocolatey) | latest |
| Starship | `starship` (AUR) | `starship` (Chocolatey) | latest |
| Yazi | `yazi` (AUR) | `yazi` (Chocolatey) | latest |
| Nerd Font | `ttf-nerd-fonts` | Install manually | JetBrainsMono recommended |

All are listed in `packages/common.txt`.

---

## Neovim Configuration

### Architecture
- **Language**: Lua (requires Neovim 0.8+ with LuaJIT)
- **Plugin Manager**: lazy.nvim (auto-installed on first startup if missing)
- **Entry Point**: `init.lua`
- **Config Flow**:
  ```
  init.lua
    ├─ require 'dldri' (lua/dldri/init.lua)
    │    ├─ require 'dldri.set'
    │    ├─ require 'dldri.remap'
    │    └─ require 'dldri.autocmd'
    └─ require('lazy').setup {
         { import = 'themes.catppuccin-mocha' },
         { import = 'plugins' }
       }
  ```

### Custom Modules
- `lua/dldri/set.lua` - Global options (leader keys, number lines, clipboard, etc.)
- `lua/dldri/remap.lua` - Keybindings (including Telescope, LSP, custom helpers)
- `lua/dldri/autocmd.lua` - Autocommands (if any)

### Plugins (17 total in `lua/plugins/`)
| Plugin | Purpose | Keymaps |
|--------|---------|---------|
| `catppuccin/nvim` | Colorscheme (mocha) | - |
| `saghen/blink.cmp` | Autocompletion | `<c-space>`, `<c-n>`, `<c-p>` |
| `L3MON4D3/LuaSnip` | Snippets | integrates with blink.cmp |
| `folke/lazydev.nvim` | Lua dev environment | - |
| `windwp/nvim-ts-autotag` | Auto-close HTML/XML tags | - |
| `nvim-treesitter/nvim-treesitter` | Syntax parsing/highlighting | - |
| `williambman/mason.nvim` | LSP package manager | `:Mason` |
| `mason-lspconfig.nvim` | Mason + lspconfig bridge | - |
| `mason-tool-installer.nvim` | Auto-install LSP tools | - |
| `neovim/nvim-lspconfig` | LSP configurations | `gd`, `K`, `<leader>vd`, `<leader>vR` |
| `nvim-telescope/telescope.nvim` | Fuzzy finder | `<leader>pf`, `<leader>sh`, `<leader>/`, etc. |
| `nvim-tree/nvim-web-devicons` | Icons for Telescope, etc. | - |
| `preservim/undotree` | Undo visualization | `<leader>u` |
| `tpope/vim-fugitive` | Git integration | `:Git`, `:G` |
| `folke/which-key.nvim` | Keybinding discoverer | `<leader>` ( delayed) |
| `folke/trouble.nvim` | Diagnostics UI | `<leader>q` |
| `JoosepAlviste/nvim-ts-conform` | Formatting | `gq` |
| `kevinhwang91/nvim-bqf` | Quickfix enhancement | - |

### Keymaps (Highlights)
- Leader: `<Space>`
- Files: `<leader>pf` (Telescope find_files), `<leader>pv` (netrw)
- Search: `<leader>sh` (help), `<leader>/` (buffer search), `<leader>ss` (Telescope picker)
- Git: `<leader>gg` ( Fugitive if mapped), `<leader>gl` (lazygit integration if added)
- LSP: `K` (hover), `gd` (definition), `<leader>vd` (diagnostic float), `<leader>vR` (rename)
- Buffer: `<leader>bd` (delete), `<leader><leader>` (buffers)
- Copy path: `<leader>yp` (cwd), `<leader>cp` (relative path), `<leader>cP` (full path), `<leader>cf` (filename), `<leader>cd` (dir)
- Misc: `<Esc>` (clear search hl), `[q`/`]q` (quickfix navigation if mapped)

---

## Wezterm Configuration

### File
`common/.config/wezterm/wezterm.lua`

### Features
- **Theme**: Catppuccin Mocha (`scheme_colors.catppuccin.mocha`)
- **Leader Key**: `CTRL-a` (tmux-style)
- **Pane Navigation**: `CTRL-a h/j/k/l`
- **Tab Management**:
  - `CTRL-a t` - new tab
  - `CTRL-a 1-9` - switch to tab index
  - `CTRL-a Ctrl-a` - send `CTRL-a` to terminal (pass-through)
  - `CTRL-a x` - close current pane
- **Status Bar**:
  - Left: `TERMINAL <tty_name>` with leader indicator when active
  - Right: `FOLDER ../current_dir` and `CALENDAR_CLOCK date time`
  - Updates every second
- **Tab Bar**: Bottom positioned, active tab highlighted in blue
- **OS Detection**:
  - Linux: `window_decorations = "NONE"` (fullscreen/undecorated)
  - Windows: `window_decorations = "RESIZE"` (for Komorebi)
- **Default Shell**:
  - Windows: `powershell.exe -NoLogo`
  - Linux: inherits from environment
- **Font**: JetBrains Mono (Nerd Font required for icons)

---

## Starship Configuration

### File
`common/.config/starship.toml`

### Overview
- Full configuration with **all** modules enabled
- Catppuccin Mocha color scheme
- Requires Nerd Fonts for proper icon display
- Modules shown (in order): username, hostname, OS, directory, Git (branch + metrics + status), package versions (node, python, ruby, rust, golang, etc.), battery, time, exit code, etc.
- Designed for `bash`, `zsh`, `fish`, `powershell`

### Integration
- **Wezterm**: inherits starship prompt automatically
- **Neovim**: can use `:terminal` without interfering
- **PowerShell**: init script includes starship hook (in windows config)

---

## Yazi Configuration

### Files
- `yazi.toml` - Main configuration
- `theme.toml` - Color theme (catppuccin-mocha)
- `init.lua` - Custom keymaps/commands (if any)

### Settings
- `show_hidden = true` (default to see dotfiles)
- Minimalist; relies on defaults for most behavior
- Integrates with `nvim` as file editor via `$EDITOR`

---

## Theme Consistency

**All configs use Catppuccin Mocha color scheme** to maintain visual harmony:
- Neovim: custom theme `lua/themes/catppuccin-mocha.lua` with black background
- Wezterm: manual color palette definition (`scheme_colors.catppuccin.mocha.*`)
- Starship: built-in catppuccin preset (or can be customized)
- Komorebi (Windows): `"theme": { "palette": "Catppuccin", "name": "Mocha" }`

---

## Notes for Agents

- Keep all paths relative; never assume absolute `$HOME` paths in configs
- When adding new common applications, update this AGENTS.md and `packages/common.txt`
- Neovim's `lazy-lock.json` should be committed to lock plugin versions
- If Stow conflicts arise (existing files), use `stow --override` or manual resolution
- Test configs on fresh installations regularly to ensure idempotency

---

**Last Updated**: 2026-03-10
**Maintainer**: dldri
