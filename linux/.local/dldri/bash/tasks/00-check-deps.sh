#!/usr/bin/env bash
# 00-check-deps.sh - Verify and install prerequisites

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/../.."

# Load libraries
source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/../lib/platform.sh"

log_info "Checking dependencies..."

# Check we're on Arch
if ! is_arch; then
    log_error "This bootstrap script requires Arch Linux or an Arch-based distribution"
    exit 1
fi

# Check for basic tools
MISSING_DEPS=()

for cmd in bash git sudo pacman; do
    if ! command -v "$cmd" &>/dev/null; then
        MISSING_DEPS+=("$cmd")
    fi
done

# Check for base-devel group
if ! has_base_devel; then
    log_warn "base-devel group is not installed (required for AUR builds)"
    MISSING_DEPS+=("base-devel")
fi

# If anything missing, try to install
if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
    log_warn "Missing dependencies: ${MISSING_DEPS[*]}"

    # Need sudo to install
    if ! sudo -v; then
        log_error "sudo privileges required to install dependencies"
        exit 1
    fi

    # Install base-devel if needed
    if [[ " ${MISSING_DEPS[*]} " =~ " base-devel " ]]; then
        log_info "Installing base-devel..."
        if sudo pacman -S --noconfirm --needed base-devel; then
            log_success "base-devel installed"
        else
            log_error "Failed to install base-devel"
            exit 1
        fi
    fi

    # For other basic tools (unlikely to be missing on Arch)
    for dep in "${MISSING_DEPS[@]}"; do
        if [[ "$dep" != "base-devel" ]] && [[ "$dep" != "bash" ]]; then
            log_info "Installing $dep..."
            sudo pacman -S --noconfirm --needed "$dep" || log_warn "Could not install $dep"
        fi
    done
fi

# Ensure yay exists (install from AUR if needed)
if ! has_yay; then
    log_warn "yay (AUR helper) is not installed"
    if confirm "Install yay from AUR?"; then
        ensure_yay || exit 1
    else
        log_error "yay is required for package installation"
        exit 1
    fi
fi

log_success "All dependencies satisfied"
