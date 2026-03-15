#!/usr/bin/env bash
# 05-remove-webapps.sh - Remove web application desktop entries

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || { echo "Error: Not in a git repository" >&2; exit 1; })"
WEBAPPS_LIST="$REPO_ROOT/packages/linux-webapps-remove.txt"

source "$SCRIPT_DIR/../lib/utils.sh"

log_info "Checking for web apps to remove..."

if [[ ! -f "$WEBAPPS_LIST" ]]; then
    log_warn "Web apps list not found: $WEBAPPS_LIST"
    log_info "No web apps will be removed"
    exit 0
fi

# Read web app list
WEBAPPS=()
while IFS= read -r app || [[ -n "$app" ]]; do
    [[ "$app" =~ ^# ]] && continue
    [[ -z "$app" ]] && continue
    WEBAPPS+=("$app")
done < "$WEBAPPS_LIST"

if [[ ${#WEBAPPS[@]} -eq 0 ]]; then
    log_info "No web apps marked for removal"
    exit 0
fi

log_info "Processing ${#WEBAPPS[@]} web apps for removal..."

DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$DESKTOP_DIR/icons"

REMOVED=0
SKIPPED=0
FAILED=0

for app in "${WEBAPPS[@]}"; do
    desktop_file="$DESKTOP_DIR/$app.desktop"
    icon_file="$ICON_DIR/$app.png"

    files_to_remove=()
    [[ -f "$desktop_file" ]] && files_to_remove+=("$desktop_file")
    [[ -f "$icon_file" ]] && files_to_remove+=("$icon_file")

    if [[ ${#files_to_remove[@]} -gt 0 ]]; then
        log_info "Removing $app..."
        for file in "${files_to_remove[@]}"; do
            if rm -f "$file"; then
                log_success "  Removed $file"
            else
                log_error "  Failed to remove $file"
                FAILED=$((FAILED+1))
                continue 2
            fi
        done
        REMOVED=$((REMOVED+1))
    else
        log_info "$app not found, skipping"
        SKIPPED=$((SKIPPED+1))
    fi
done

log_success "Web app cleanup complete. Removed: $REMOVED, Skipped: $SKIPPED, Failed: $FAILED"

if [[ $FAILED -gt 0 ]]; then
    exit 1
fi

exit 0
