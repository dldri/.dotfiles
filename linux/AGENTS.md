# Linux Bootstrap - Agent Context

## Purpose

The `linux/` directory contains scripts for automated setup of an Arch-based Linux system. The entry point is `bootstrap.sh` which orchestrates a series of tasks to install packages and symlink dotfiles.

## Proposed Structure

```
linux/.local/dldri/bash/
├── bootstrap.sh          # Main entry point (executable)
├── lib/                  # Shared utility functions
│   ├── utils.sh         # Colors, logging, progress
│   ├── platform.sh      # OS/distro detection
│   └── stow.sh          # Stow wrapper with error handling
└── tasks/               # Individual setup steps (numbered for order)
    ├── 00-check-deps.sh   # Verify prerequisites (bash, git, sudo, base-devel)
    ├── 01-cleanup.sh      # Remove unwanted default packages (PLACEHOLDER)
    ├── 02-packages.sh     # Install packages from ../../packages/linux.txt
    ├── 03-stow.sh         # Symlink dotfiles: stow common linux
    └── 04-post-setup.sh   # Optional finalization (PLACEHOLDER)
```

**Note**: The current `linux/.local/dldri/bash/scripts/` directory (containing `install-stow.sh`, `install-oh-my-posh.sh`) is deprecated and will be replaced by this new structure.

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
**PLACEHOLDER** - User will define later.
Template structure with comments showing common Arch cleanup:
```bash
#!/bin/bash
# Optional: Remove unwanted default packages
# Examples:
# - Remove nano if using neovim
# - Remove pulseaudio if using pipewire
# - Remove man-db if using tldr
# User will specify exact package names
```

### 02-packages.sh
- Read package list from `../../packages/linux.txt`
- Skip blank lines and comments (`#`)
- Install each package via `yay -S --noconfirm --needed <pkg>`
- Print progress: "Installing <pkg>..." and "✓ <pkg> installed" or "⊘ <pkg> already up-to-date"
- Handle failures gracefully (continue to next package, report errors at end)

### 03-stow.sh
- Change to repo root (`cd "$(git rev-parse --show-toplevel 2>/dev/null || echo ../..)"`)
- Create backup of any existing conflicting dotfiles? (Decision needed)
- Run: `stow -t $HOME --simulate common linux` → show plan
- Prompt user to continue or abort
- Run: `stow -t $HOME --verbose common linux`
- Report success/failures

### 04-post-setup.sh
**PLACEHOLDER** - User will define later.
Possible tasks (to be filled):
- `nvim --headless +'Lazy! sync' +qa`
- Generate shell config (`.bashrc`, `.zshrc`) with starship, zoxide
- Set up yazi keymap cache
- Enable/start services (if any)

## Standards

- **Idempotency**: All tasks must be re-runnable without side effects
- **Safety**: Use `--noconfirm --needed` with yay; check before removing packages
- **Logging**: Clear status messages; use colors (green ✓, yellow ⊘, red ✗)
- **Error Handling**: `set -e` at top; trap ERR to print helpful messages
- **Paths**: Use relative paths from repo root; detect root via git or script location

## Integration with Root AGENTS.md

This folder follows the repository-wide conventions defined in `../AGENTS.md`. See that file for:
- Package list format and maintenance
- Stow strategy details
- Overall bootstrap workflow

---

**Last Updated**: 2026-03-10
**Maintainer**: dldri
