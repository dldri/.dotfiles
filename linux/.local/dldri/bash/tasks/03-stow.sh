#!/usr/bin/env bash
# 03-stow.sh - Symlink dotfiles using GNU Stow

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/../.."

source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/../lib/stow.sh"

log_info "Preparing to stow dotfiles..."

# Determine which packages to stow
# By default: common and linux (and hyprland if it exists in linux/.config)
PACKAGES=("common" "linux")

# Check if hyprland config exists
if [[ -d "$REPO_ROOT/linux/.config/hyprland" ]]; then
    log_info "Detected hyprland config in linux/.config/"
    # Note: hyprland is inside linux/.config, so stowing 'linux' covers it
    # No action needed - just informational
fi

# Run stow workflow
if stow_packages "${PACKAGES[@]}"; then
    log_success "Stow completed"
    exit 0
else
    log_error "Stow failed or was aborted"
    exit 1
fi
