# Windows Configuration - Agent Context

## Purpose

The `windows/` directory contains native Windows configuration files. Currently **no automated bootstrap** exists; these are manual reference configs. A future PowerShell/Chocolatey bootstrap may be implemented.

## Directory Structure

```
windows/
└── .config/
    ├── kanata/
    │   └── kanata.kbd       # Keyboard remapping (dual-role keys)
    ├── komorebi/
    │   └── komorebi/
    │       ├── komorebi.json          # Main WM configuration
    │       ├── applications.json      # App-specific rules
    │       ├── komorebi.bar.monitor1.json
    │       ├── komorebi.bar.monitor2.json
    │       └── komorebi.bar.monitor3.json
    ├── pwsh/
    │   └── profile.ps1      # PowerShell profile (oh-my-posh, zoxide)
    └── whkd/
        └── whkdrc           # Window hotkey daemon config
```

All files in `windows/.config/` are intended to be linked to `%USERPROFILE%\.config\` (on Windows).

---

## Current Status: Configs Only

- **No bootstrap script**: Manual setup required
- **Package manager**: Chocolatey recommended (see `packages/windows.txt`)
- **Manual steps** (for now):
  1. Install Chocolatey
   2. Install packages: `choco install -y wezterm neovim starship yazi komorebi kanata whkd oh-my-posh zoxide 7zip`
  3. Copy `windows/.config/` to `%USERPROFILE%\.config\`
  4. Add PowerShell profile: copy `pwsh/profile.ps1` to `$PROFILE`
  5. Configure Komorebi to replace Explorer (registry tweak - see Komorebi docs)

---

## Configuration Details

### Kanata (`kanata.kbd`)
- Keyboard remapping tool with layered configuration
- Defines home row mods (Caps+A/O/E/U/H/T/N/S as dual-role: tap = key, hold = modifier)
- Space bar as layer toggle (tap-hold)
- Layer 1: Navigation (Home/Up/End/Left/Down/Right)
- Requires: `kanata` binary from AUR/Chocolatey

### Komorebi (`.komorebi.json`)
- Tiling window manager for Windows
- Theme: Catppuccin Mocha with Teal accents
- Layout: BSP across 5 workspaces (I-V)
- Border: 4px width, focused/unfocused colors
- Bar configurations per monitor (JSON files)
- Requires: `komorebi` + `whkd` (hotkeys)
- **Registry integration**: Replace Explorer shell with komorebi (manual)

### PowerShell Profile (`profile.ps1`)
- **oh-my-posh**: catppuccin_mocha theme
- **zoxide**: Tab completion and jump
- **Alias**: `vim` → `nvim`
- Location: `%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`

### WHKD (`whkdrc`)
- Window hotkey daemon that sends commands to komorebi
- Keybindings (Alt-based):
  - Alt+h/j/k/l: focus windows
  - Alt+Shift+h/j/k/l: move windows
  - Alt+Ctrl+1..8: switch workspaces
  - Alt+Shift+1..8: move to workspace
  - Alt+m: minimize, Alt+q: close, Alt+t: toggle float
  - Many more (stacking, resizing, monitors)
- Shell: PowerShell (required for komorebi commands)

---

## Future Bootstrap Plan

A future Windows bootstrap (PowerShell) may follow this structure:

```
windows/.local/dldri/powershell/
├── bootstrap.ps1
├── lib/
│   ├── utils.ps1
│   └── platform.ps1
└── tasks/
    ├── 00-check-deps.ps1
    ├── 01-cleanup.ps1
    ├── 02-packages.ps1      # choco install from packages/windows.txt
    └── 03-post-setup.ps1
```

**Package Manager**: Chocolatey (community consensus). Alternatives: Scoop, winget.

---

## Dependencies (from `packages/windows.txt`)

- **Terminal**: Wezterm
- **Shell**: PowerShell 7+, starship
- **Editor**: Neovim
- **File Manager**: Yazi
- **Window Management**: Komorebi, WHKD
- **Keyboard Remapping**: Kanata
- **Utilities**: oh-my-posh, zoxide, git, curl, wget
- **Archiving**: 7zip

All configs use Catppuccin Mocha for consistent theming across platforms.

---

## Notes for Agents

- Komorebi requires registry edit to replace Explorer (HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders)
- Kanata runs as a service; WHKD runs as background process
- Ensure Nerd Font (JetBrainsMono) installed for starship/wezterm icons
- PowerShell execution policy may need adjustment (`Set-ExecutionPolicy RemoteSigned`)

---

**Last Updated**: 2026-03-10
**Maintainer**: dldri
