#!/usr/bin/env bash
# Platform detection and dependency installation functions

# Check if running on Arch Linux
is_arch() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        [[ "$ID" == "arch" ]] || [[ "$ID_LIKE" =~ arch ]]
    else
        uname | grep -qi linux
    fi
}

# Check if base-devel group is installed
has_base_devel() {
    pacman -Q base-devel &>/dev/null
}

# Install base-devel group
ensure_base_devel() {
    log_info "Installing base-devel group..."
    if sudo pacman -S --noconfirm --needed base-devel; then
        log_success "base-devel installed"
        return 0
    else
        log_error "Failed to install base-devel"
        return 1
    fi
}

# Check if yay is installed
has_yay() {
    command -v yay &>/dev/null
}

# Install yay from AUR
ensure_yay() {
    log_info "Installing yay (AUR helper)..."
    if ! has_base_devel; then
        ensure_base_devel || return 1
    fi

    # Clone yay if not already present
    local build_dir="/tmp/yay-build"
    if [[ -d "$build_dir" ]]; then
        rm -rf "$build_dir"
    fi

    git clone https://aur.archlinux.org/yay.git "$build_dir"
    (
        cd "$build_dir"
        makepkg -si --noconfirm
    )
    rm -rf "$build_dir"

    if command -v yay &>/dev/null; then
        log_success "yay installed"
        return 0
    else
        log_error "yay installation failed"
        return 1
    fi
}

# Ensure yay exists, install if missing
require_yay() {
    if has_yay; then
        return 0
    fi

    if ! is_arch; then
        log_error "This script requires Arch Linux or an Arch-based distribution"
        return 1
    fi

    log_warn "yay not found. Will attempt to install it."
    if confirm "Install yay from AUR? (requires base-devel)"; then
        ensure_yay
    else
        log_error "yay is required to continue"
        return 1
    fi
}
