#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INSTALL_LIST="$REPO_ROOT/packages/linux.txt"

source "$SCRIPT_DIR/lib/utils.sh"

log_info "Starting package installation..."

# Check yay exists
if ! command -v yay &>/dev/null; then
    log_error "yay (AUR helper) not found. Please install it first."
    exit 1
fi

INSTALLED=0
SKIPPED=0
FAILED=0
INSTALL_PKGS=()

# Read package list
if [[ ! -f "$INSTALL_LIST" ]]; then
    log_error "Install list not found: $INSTALL_LIST"
    exit 1
fi

while IFS= read -r pkg || [[ -n "$pkg" ]]; do
    [[ "$pkg" =~ ^# ]] && continue
    [[ -z "$pkg" ]] && continue
    INSTALL_PKGS+=("$pkg")
done < "$INSTALL_LIST"

if [[ ${#INSTALL_PKGS[@]} -eq 0 ]]; then
    log_warn "No packages to install."
    exit 0
fi

log_info "Installing ${#INSTALL_PKGS[@]} packages..."
require_sudo

for pkg in "${INSTALL_PKGS[@]}"; do
    if is_installed "$pkg"; then
        log_info "$pkg already installed, skipping"
        ((SKIPPED++))
    else
        log_info "Installing $pkg..."
        if yay -S --noconfirm --needed "$pkg"; then
            ((INSTALLED++))
            log_success "Installed $pkg"
        else
            log_error "Failed to install $pkg"
            ((FAILED++))
        fi
    fi
done

log_success "Installation complete. Installed: $INSTALLED, Skipped: $SKIPPED, Failed: $FAILED"
if [[ $FAILED -gt 0 ]]; then
    exit 1
fi
