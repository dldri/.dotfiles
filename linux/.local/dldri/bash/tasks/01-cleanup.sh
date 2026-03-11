#!/usr/bin/env bash
# 01-cleanup.sh - Remove unwanted packages

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get repository root via git
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || { echo "Error: Not in a git repository" >&2; exit 1; })"
REMOVE_LIST="$REPO_ROOT/packages/linux-remove.txt"

source "$SCRIPT_DIR/../lib/utils.sh"

log_info "Checking for packages to remove..."

if [[ ! -f "$REMOVE_LIST" ]]; then
    log_warn "Removal list not found: $REMOVE_LIST"
    log_info "No packages will be removed"
    exit 0
fi

# Read package list
REMOVE_PKGS=()
while IFS= read -r pkg || [[ -n "$pkg" ]]; do
    [[ "$pkg" =~ ^# ]] && continue
    [[ -z "$pkg" ]] && continue
    REMOVE_PKGS+=("$pkg")
done < "$REMOVE_LIST"

if [[ ${#REMOVE_PKGS[@]} -eq 0 ]]; then
    log_info "No packages marked for removal"
else
    log_info "Processing ${#REMOVE_PKGS[@]} packages for removal..."
    require_sudo

    for pkg in "${REMOVE_PKGS[@]}"; do
        if is_installed "$pkg"; then
            log_info "Removing $pkg..."
            if sudo pacman -R --noconfirm "$pkg"; then
                log_success "Removed $pkg"
            else
                log_error "Failed to remove $pkg"
            fi
        else
            log_info "$pkg not installed, skipping"
        fi
    done
fi

# Clean up orphaned dependencies
ORPHANS=$(pacman -Qdtq 2>/dev/null || true)
if [[ -n "$ORPHANS" ]]; then
    log_info "Removing $(echo "$ORPHANS" | wc -w) orphaned dependencies..."
    if echo "$ORPHANS" | xargs -r sudo pacman -Rns --noconfirm; then
        log_success "Orphaned dependencies cleaned"
    else
        log_warn "Some orphans could not be removed"
    fi
else
    log_info "No orphaned dependencies found"
fi

log_success "Cleanup complete"
