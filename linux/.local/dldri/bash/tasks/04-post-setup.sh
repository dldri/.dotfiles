#!/usr/bin/env bash
# 04-post-setup.sh - Finalization and summary

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../lib/utils.sh"

log_info "Running post-setup tasks..."

# Summary timestamp
echo "========================================"
echo "Dotfiles Bootstrap Complete"
echo "Completed: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
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

log_success "Bootstrap finished! Enjoy your new setup."
