# Linux Bootstrap - Agent Context

## Purpose

The `linux/` directory contains scripts for automated setup of an Arch-based Linux system. The entry point is `bootstrap.sh` which orchestrates a series of tasks to install packages and symlink dotfiles.

## Proposed Structure

```
linux/.local/dldri/bash/
├── bootstrap.sh          # Main entry point (executable)
├── lib/                  # Shared utility functions
│   ├── utils.sh         # Colors, logging, progress
│   └── platform.sh      # OS/distro detection
└── tasks/               # Individual setup steps (numbered for order)
    ├── 00-check-deps.sh      # Verify prerequisites (bash, git, sudo, base-devel)
    ├── 01-cleanup.sh         # Remove unwanted default packages
    ├── 02-packages.sh        # Install packages from ../../packages/linux-install.txt
    ├── 03-post-setup.sh      # Finalization and summary
    └── 04-hyprpm-plugins.sh  # Manage Hyprland plugins via hyprpm
```

**Note**: The legacy scripts (`setup.sh`, `install-packages.sh`, `remove-packages.sh`) are deprecated. Use `bootstrap.sh` for full system setup. Individual task scripts remain available for granular execution.

## Entry Point

**Script**: `bootstrap.sh`
**Location**: `~/.dotfiles/linux/.local/dldri/bash/` (run from repo root or detect path)
**Usage**: `./bootstrap.sh`
**Behavior**:

- Executes tasks in order (00 → 04)
- Exits on error (`set -e`)
- Prints colored status messages
- Idempotent (safe to re-run)

## Dependencies (Prerequisites)

- Arch Linux or Arch-based distribution
- `sudo` privileges
- `git`, `curl`, `base-devel` group (for AUR building)
- Internet connection

`00-check-deps.sh` will verify these and offer to install missing ones if possible.

## Task Specifications

### 00-check-deps.sh

- Check for `bash`, `git`, `sudo`, `base-devel` (makepkg, gcc, etc.)
- If `yay` missing, check if can be installed from AUR (requires base-devel)
- Prompt user to install missing deps or abort

### 01-cleanup.sh

- Reads `packages/linux-remove.txt` (blank lines and `#` comments ignored)
- For each package: if installed → `sudo pacman -R --noconfirm`
- Then removes orphaned dependencies via `pacman -Qdtq | xargs sudo pacman -Rns --noconfirm`
- Safe and idempotent: skips packages not installed

### 02-packages.sh

- Read package list from `../../packages/linux-install.txt`
- Skip blank lines and comments (`#`)
- Install each package via `yay -S --noconfirm --needed <pkg>`
- Print progress: "Installing <pkg>..." and "✓ <pkg> installed" or "⊘ <pkg> already up-to-date"
- Handle failures gracefully (continue to next package, report errors at end)

### 03-post-setup.sh

- Prints a timestamped bootstrap completion summary
- Suggests next steps (shell reload, Neovim Lazy sync, Hyprland reboot)
- Cleans temporary build directories (e.g., `/tmp/yay-build`)
- Informational only; no interactive prompts

### 04-hyprpm-plugins.sh

- Reads `packages/hyprland-plugins.txt` (blank lines and `#` comments ignored)
- For each plugin URI:
  - Extracts plugin name from the URI (last path segment)
  - Uses `hyprpm` to add the plugin if not already added (`hyprpm add <uri>`)
  - Enables the plugin if not already enabled (`hyprpm enable <plugin>`)
- Requires `hyprpm` to be installed and available in PATH
- Idempotent: safe to re-run; skips already added/enabled plugins
- Prints status for each plugin; continues on errors, reports at end

## Standards

- **Idempotency**: All tasks must be re-runnable without side effects
- **Safety**: Use `--noconfirm --needed` with yay; check before removing packages
- **Logging**: Clear status messages; use colors (green ✓, yellow ⊘, red ✗)
- **Error Handling**: `set -e` at top; trap ERR to print helpful messages
- **Paths**: Use relative paths from repo root; detect root via git or script location

## Integration with Root AGENTS.md

This folder follows the repository-wide conventions defined in `../AGENTS.md`. See that file for:

- Package list format and maintenance
- Overall bootstrap workflow

---

**Last Updated**: 2026-03-10
**Maintainer**: dldri
