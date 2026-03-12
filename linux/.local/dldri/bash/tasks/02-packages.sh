#!/usr/bin/env bash
# 02-packages.sh - Install packages from linux-install.txt

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get repository root via git
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || { echo "Error: Not in a git repository" >&2; exit 1; })"
INSTALL_LIST="$REPO_ROOT/packages/linux-install.txt"

source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/../lib/platform.sh"

log_info "Starting package installation..."

# Ensure yay exists
require_yay

# Read package list
if [[ ! -f "$INSTALL_LIST" ]]; then
    log_error "Install list not found: $INSTALL_LIST"
    exit 1
fi

INSTALL_PKGS=()
while IFS= read -r pkg || [[ -n "$pkg" ]]; do
    [[ "$pkg" =~ ^# ]] && continue
    [[ -z "$pkg" ]] && continue
    INSTALL_PKGS+=("$pkg")
done < "$INSTALL_LIST"

# Read common packages if available
COMMON_LIST="$REPO_ROOT/packages/common.txt"
COMMON_PKGS=()
if [[ -f "$COMMON_LIST" ]]; then
    while IFS= read -r pkg || [[ -n "$pkg" ]]; do
        [[ "$pkg" =~ ^# ]] && continue
        [[ -z "$pkg" ]] && continue
        COMMON_PKGS+=("$pkg")
    done < "$COMMON_LIST"
else
    log_warn "common.txt not found: $COMMON_LIST - skipping common packages"
fi

# Combine and deduplicate - prefer common.txt order first, then linux-install.txt
declare -A SEEN
ALL_PKGS=()
for pkg in "${COMMON_PKGS[@]}" "${INSTALL_PKGS[@]}"; do
    if [[ -z "${SEEN[$pkg]:-}" ]]; then
        ALL_PKGS+=("$pkg")
        SEEN[$pkg]=1
    fi
done

if [[ ${#ALL_PKGS[@]} -eq 0 ]]; then
    log_warn "No packages to install."
    exit 0
fi

log_info "Installing ${#ALL_PKGS[@]} packages (${#COMMON_PKGS[@]} common, ${#INSTALL_PKGS[@]} linux-specific)..."
require_sudo

INSTALLED=0
SKIPPED=0
FAILED=0

for pkg in "${ALL_PKGS[@]}"; do
    if is_installed "$pkg"; then
        log_info "$pkg already installed, skipping"
        : $((SKIPPED++))
    else
        log_info "Installing $pkg..."
        if yay -S --noconfirm --needed "$pkg"; then
            : $((INSTALLED++))
            log_success "Installed $pkg"
        else
            log_error "Failed to install $pkg"
            : $((FAILED++))
        fi
    fi
done

log_success "Installation complete. Installed: $INSTALLED, Skipped: $SKIPPED, Failed: $FAILED"

if [[ $FAILED -gt 0 ]]; then
    exit 1
fi
