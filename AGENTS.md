# .dotfiles Repository - Agent Context

## Repository Purpose

Cross-platform dotfiles repository for a reproducible, declarative development environment setup. Targets:
- **Linux** (Arch-based) - primary platform with automated bootstrap
- **Windows** - configuration files with planned Chocolatey bootstrap
- **Common** - cross-platform applications shared across all platforms

Philosophy: Use GNU Stow for symlink management, package lists for dependency installation, and idempotent scripts for reliable setup on any new machine.

---

## Directory Structure

```
.dotfiles/
├── AGENTS.md                 # This file - repository-wide context
├── packages/                 # Package lists by platform (user-maintained)
│   ├── common.txt           # Packages for all platforms
│   ├── linux.txt            # Arch/AUR packages
│   └── windows.txt          # Chocolatey packages
├── common/.config/           # Cross-platform configs (stowed to $HOME/.config/)
│   ├── nvim/                # Neovim (Lua) - main editor
│   ├── wezterm/wezterm.lua  # Wezterm terminal emulator
│   ├── starship.toml        # Shell prompt
│   └── yazi/                # File manager
├── linux/.local/dldri/bash/ # Linux bootstrap scripts
│   ├── bootstrap.sh         # Main entry point **(TO BE CREATED)**
│   ├── lib/                 # Shared utilities **(TO BE CREATED)**
│   └── tasks/               # Individual setup steps **(TO BE CREATED)**
│       ├── 00-check-deps.sh
│       ├── 01-cleanup.sh    # Placeholder - user will define
│       ├── 02-packages.sh
│       ├── 03-stow.sh
│       └── 04-post-setup.sh # Placeholder - user will define
└── windows/.config/         # Windows-specific configs (stowed on Windows)
    ├── kanata/              # Keyboard remapping
    ├── komorebi/            # Tiling window manager
    ├── pwsh/profile.ps1     # PowerShell profile
    └── whkd/                # Window hotkeys
```

---

## Platform Support Strategy

| Platform | Bootstrap | Package Manager | Stow Targets |
|----------|-----------|-----------------|--------------|
| Linux    | ✅ `bootstrap.sh` | yay (AUR) | `common/`, `linux/` |
| Windows  | 🔜 Planned | Chocolatey | `common/`, `windows/` |
| macOS    | ❌ Not yet | Homebrew | TBD |

**Current status**: Linux bootstrap is the primary focus. Windows has configuration files but no automated installer yet.

---

## Bootstrap Workflow (Linux)

```
1. Clone repository to $HOME/.dotfiles/
   $ git clone <repo> ~/.dotfiles/

2. Run the bootstrap script
   $ cd ~/.dotfiles/linux/.local/dldri/bash/
   $ ./bootstrap.sh

3. Script execution order:
   a. 00-check-deps.sh - Verify prerequisites (bash, git, sudo, base-devel)
   b. 01-cleanup.sh - Remove unwanted default packages (user-defined)
   c. 02-packages.sh - Install packages from ../../packages/linux.txt
   d. 03-stow.sh - Symlink dotfiles: stow common linux
   e. 04-post-setup.sh - Optional finalization (placeholder)
```

**Idempotency**: All scripts should be safe to re-run. They must check for existing installations and skip if already present.

---

## Package Management Conventions

### Package List Format
- One package name per line
- Lines starting with `#` are comments
- Blank lines are ignored
- Packages are platform-specific (AUR names for Linux, Chocolatey names for Windows)

### Maintenance
- **`packages/linux.txt`**: Arch/AUR packages. Order doesn't matter but group logically.
- **`packages/windows.txt`**: Chocolatey package names. Validate with `choco search <pkg>`.
- **`packages/common.txt`**: Cross-platform tools that should exist on all systems. Used to keep package lists in sync.

When adding a new tool:
1. Add package name to appropriate `packages/*.txt` file
2. Ensure corresponding config exists in `common/`, `linux/`, or `windows/`
3. Update AGENTS.md if structure changes

---

## Adding New Configurations

1. **Determine platform**: Place config in `common/`, `linux/`, or `windows/`
2. **Follow `.config/<app>/` structure**: Keep configs organized by application name
3. **Add dependencies**: If the app needs a package, add it to the relevant `packages/*.txt`
4. **Document**: Update the AGENTS.md in that folder if the config is significant
5. **Stowable**: Ensure the folder can be symlinked directly (use relative paths inside configs)

---

## Existing Configurations Summary

### Neovim (`common/.config/nvim/`)
- **Version**: Lua-based, requires Neovim ≥ 0.8 with LuaJIT
- **Plugin Manager**: lazy.nvim (auto-installed on first run if missing)
- **Configuration**:
  - `init.lua` loads `lazy.nvim` and imports `plugins/`, `themes/catppuccin-mocha`
  - Custom modules in `lua/dldri/`: `set.lua`, `remap.lua`, `autocmd.lua`
- **Plugins** (18 total):
  - `catppuccin/nvim` - colorscheme (mocha variant, transparent black background)
  - `saghen/blink.cmp` - autocompletion with LuaSnip
  - `L3MON4A3/LuaSnip` - snippets
  - `folke/lazydev.nvim` - Lua dev environment
  - `windwp/nvim-ts-autotag` - auto-close/rename HTML tags
  - `nvim-treesitter/nvim-treesitter` - syntax parsing
  - `williambman/mason.nvim` + `mason-lspconfig.nvim` + `mason-tool-installer.nvim` - LSP management
  - `neovim/nvim-lspconfig` - LSP configurations
  - `nvim-telescope/telescope.nvim` + extensions - fuzzy finder
  - `nvim-tree/nvim-web-devicons` - icons
  - `romgrk/barbar.nvim` - tabline (if needed)
  - `kyazdani42/nvim-tree.lua` - file explorer (if needed)
  - `preservim/undotree` - undo visualization
  - `tpope/vim-fugitive` - Git integration
  - `folke/which-key.nvim` - keybinding discoverer
  - `folke/trouble.nvim` - diagnostics UI
  - `JoosepAlviste/nvim-ts-conform` - formatting
  - `kevinhwang91/nvim-bqf` - quickfix enhancement
- **Keymaps**:
  - Leader: `Space`
  - Telescope: `<leader>sh` (help), `<leader>sk` (keymaps), `<leader>pf` (files), `<leader>/` (buffer search)
  - Buffer delete: `<leader>bd`
  - Netrw (file browser): `<leader>pv` (`:Ex`)
  - Diagnostics: `<leader>vd` (float), `<leader>q` (quickfix)
- **Lock file**: `lazy-lock.json` committed for reproducible plugin versions

### Wezterm (`common/.config/wezterm/wezterm.lua`)
- **Purpose**: Terminal emulator with tmux-like multiplexing
- **Theme**: Catppuccin Mocha (matches Neovim)
- **Keybindings** (Leader = `Ctrl-a`):
  - `Ctrl-a h/j/k/l` - navigate panes
  - `Ctrl-a t` - new tab
  - `Ctrl-a x` - close pane
  - `Ctrl-a 1-9` - switch tabs
  - `Ctrl-a Ctrl-a` - send `Ctrl-a` to terminal (pass-through)
- **Status Bar**:
  - Left: terminal indicator, workspace name, leader key status
  - Right: current directory, date/time
  - Updates every second
- **Tabs**: Bottom tab bar with active/inactive styling
- **OS Detection**: Adjusts window decorations (NONE on Linux, RESIZE on Windows for Komorebi)
- **Default shell**: PowerShell on Windows, inherits on Linux

### Starship (`common/.config/starship.toml`)
- Full configuration with all modules enabled
- Catppuccin Mocha color scheme throughout
- Shows: username, hostname, OS, directory, Git branch/status, package/node/python/rust/etc versions, battery, time, exit code, etc.
- Designed for Nerd Fonts

### Yazi (`common/.config/yazi/`)
- `yazi.toml`: minimal config, `show_hidden = true`
- `theme.toml`: catppuccin-mocha colors (if customized)
- `init.lua`: custom keymaps/commands (if any)

---

## Known Gaps & Future Work

- [ ] **Windows bootstrap**: PowerShell script using Chocolatey (not implemented)
- [ ] **Cleanup definition**: `01-cleanup.sh` contents to be specified by user
- [ ] **Post-setup tasks**: `04-post-setup.sh` for Neovim plugin sync, shell config generation, etc.
- [ ] **macOS support**: Brewfile and bootstrap for macOS (future)
- [ ] **Package list validation**: Need to verify all package names exist in AUR/Chocolatey
- [ ] **Unified shell config**: `.bashrc`/`.zshrc` generation with starship, zoxide, etc. (currently Neovim only)

---

## Standards for Agents

When working in this repository:
1. **Follow existing patterns**: Neovim config uses Lua modules in `lua/dldri/`; keep similar structure if adding plugins
2. **Use package lists**: Never hardcode package names in scripts; always read from `packages/*.txt`
3. **Keep scripts idempotent**: Check if command already ran, skip if done
4. **Preserve catppuccin**: All configs use catppuccin-mocha; maintain color consistency
5. **Document changes**: Update AGENTS.md files if structure or conventions change
6. **Test on fresh VM**: Bootstrap should work on a clean Arch install (Simulator: `archlinux:latest` Docker)

---

## Questions for Future Agents

- Should we split `packages/linux.txt` into `pacman.txt` (official repos) and `aur.txt` (AUR) for clarity?
- Should `bootstrap.sh` accept arguments (e.g., `--skip-cleanup`, `--dry-run`)?
- Should we add a `--uninstall` mode to remove all dotfiles and packages?
- Should Windows bootstrap use PowerShell or WSL? (Current configs are native Windows)

---

**Last Updated**: 2026-03-10
**Maintainer**: dldri
