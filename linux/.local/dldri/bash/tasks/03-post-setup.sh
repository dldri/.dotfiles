#!/usr/bin/env bash
# 03-post-setup.sh - Finalization and summary

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../lib/utils.sh"

log_info "Running post-setup tasks..."

# Configure git aliases
if command -v git &>/dev/null; then
    log_info "Configuring git aliases..."
    if git config --global alias.lg &>/dev/null; then
        log_info "Git alias 'lg' already exists, skipping"
    else
        git config --global alias.lg "log --oneline --graph --all"
        log_success "Git alias 'lg' configured"
    fi
fi

# --- Tailscale Setup ---
log_info "Setting up Tailscale..."

# Enable and start tailscaled service (idempotent - safe to re-run)
if systemctl is-active --quiet tailscaled; then
    log_info "tailscaled service is already running"
else
    log_info "Enabling and starting tailscaled service..."
    if sudo systemctl enable --now tailscaled; then
        log_success "tailscaled service enabled and started"
    else
        log_warn "Failed to enable/start tailscaled service"
    fi
fi

echo ""

# Summary timestamp
echo "========================================"
echo "Dotfiles Bootstrap Complete"
echo "Completed: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
echo ""

# Reload hypridle service if installed and running
if pacman -Q hypridle &>/dev/null; then
    if systemctl --user is-active --quiet hypridle.service; then
        log_info "Reloading hypridle service to apply config changes..."
        if systemctl --user restart hypridle.service; then
            log_success "hypridle service restarted"
        else
            log_error "Failed to restart hypridle service"
        fi
    else
        log_info "hypridle service is not running (will start on next Hyprland session)"
    fi
else
    log_info "hypridle not installed; skipping service reload"
fi
echo ""

# Optional: Sync Neovim plugins if nvim is installed
if command -v nvim &>/dev/null; then
    log_info "Neovim detected. You may want to sync plugins:"
    echo "  nvim --headless +'Lazy! sync' +qa"
    echo ""
fi

# Optional: Suggest shell reload
log_info "To apply changes to your shell, you may need to:"
echo "  source ~/.bashrc   # or ~/.zshrc, ~/.config/fish/config.fish"
echo ""

# Clean any temporary build directories if present
TEMP_DIRS=("/tmp/yay-build" "/tmp/yay-*")
for dir in "${TEMP_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        rm -rf "$dir" 2>/dev/null
    fi
done

log_success "Post-setup tasks completed."
