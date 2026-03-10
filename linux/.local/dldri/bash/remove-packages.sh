#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REMOVE_LIST="$REPO_ROOT/packages/linux-remove.txt"

# Source utils
source "$SCRIPT_DIR/lib/utils.sh"

log_info "Starting package removal process..."

# Track stats
REMOVED=0
SKIPPED=0
REMOVE_PKGS=()

# Read package list
if [[ ! -f "$REMOVE_LIST" ]]; then
    log_warn "Removal list not found: $REMOVE_LIST"
    exit 0
fi

while IFS= read -r pkg || [[ -n "$pkg" ]]; do
    # Skip comments and blank lines
    [[ "$pkg" =~ ^# ]] && continue
    [[ -z "$pkg" ]] && continue
    REMOVE_PKGS+=("$pkg")
done < "$REMOVE_LIST"

if [[ ${#REMOVE_PKGS[@]} -eq 0 ]]; then
    log_info "No packages marked for removal."
else
    log_info "Will process ${#REMOVE_PKGS[@]} packages for removal..."
    require_sudo

    for pkg in "${REMOVE_PKGS[@]}"; do
        if is_installed "$pkg"; then
            log_info "Removing $pkg..."
            if sudo pacman -R --noconfirm "$pkg"; then
                ((REMOVED++))
                log_success "Removed $pkg"
            else
                log_error "Failed to remove $pkg"
            fi
        else
            log_info "$pkg not installed, skipping"
            ((SKIPPED++))
        fi
    done
fi

# Clean up orphaned dependencies
ORPHANS=$(pacman -Qdtq 2>/dev/null || true)
if [[ -n "$ORPHANS" ]]; then
    log_info "Removing orphaned dependencies..."
    require_sudo
    if sudo pacman -Rns --noconfirm $ORPHANS; then
        log_success "Orphans cleaned"
    else
        log_warn "Some orphans could not be removed"
    fi
else
    log_info "No orphaned dependencies found"
fi

log_success "Removal complete. Removed: $REMOVED, Skipped: $SKIPPED"
