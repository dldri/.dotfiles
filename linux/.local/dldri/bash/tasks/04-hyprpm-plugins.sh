#!/usr/bin/env bash
# 04-hyprpm-plugins.sh - Install and enable Hyprland plugins via hyprpm

set -euo pipefail

# Get repository root via git
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || { echo "Error: Not in a git repository" >&2; exit 1; })"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/../lib/platform.sh"

PLUGINS_LIST="$REPO_ROOT/packages/hyprland-plugins.txt"

log_info "Setting up Hyprland plugins via hyprpm..."

# Verify hyprpm is installed
if ! command -v hyprpm &>/dev/null; then
    log_error "hyprpm not found in PATH. Ensure it's installed via packages/linux-install.txt"
    exit 1
fi

# Update hyprpm plugin database to match Hyprland headers
log_info "Updating hyprpm database..."
if hyprpm update; then
    log_success "hyprpm updated"
else
    log_warn "hyprpm update failed - continuing anyway (plugins may not be compatible)"
fi

# Read plugin list
if [[ ! -f "$PLUGINS_LIST" ]]; then
    log_warn "Plugins list not found: $PLUGINS_LIST - skipping"
    exit 0
fi

PLUGIN_URIS=()
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^# ]] && continue
    [[ -z "$line" ]] && continue
    PLUGIN_URIS+=("$line")
done < "$PLUGINS_LIST"

if [[ ${#PLUGIN_URIS[@]} -eq 0 ]]; then
    log_info "No hyprland plugins specified."
    exit 0
fi

log_info "Processing ${#PLUGIN_URIS[@]} plugin(s)..."

ADDED=0
ENABLED=0
SKIPPED=0
FAILED=0

for uri in "${PLUGIN_URIS[@]}"; do
    # Extract plugin name from URI (last path segment)
    plugin_name="$(basename "$uri")"

    log_info "Checking plugin: $plugin_name"

    # Check if already added
    if hyprpm list 2>/dev/null | grep -q "^$plugin_name "; then
        log_info "  Plugin '$plugin_name' already added"
    else
        log_info "  Adding plugin '$plugin_name' from $uri..."
        if hyprpm add "$uri"; then
            log_success "  Added $plugin_name"
            : $((ADDED++))
        else
            log_error "  Failed to add $plugin_name"
            : $((FAILED++))
            continue
        fi
    fi

    # Check if already enabled
    if hyprpm list 2>/dev/null | grep -q "^$plugin_name.*enabled"; then
        log_info "  Plugin '$plugin_name' already enabled"
        : $((SKIPPED++))
    else
        log_info "  Enabling plugin '$plugin_name'..."
        if hyprpm enable "$plugin_name"; then
            log_success "  Enabled $plugin_name"
            : $((ENABLED++))
        else
            log_error "  Failed to enable $plugin_name"
            : $((FAILED++))
        fi
    fi
done

log_success "Hyprpm plugins setup complete. Added: $ADDED, Enabled: $ENABLED, Already correct: $SKIPPED, Failed: $FAILED"

if [[ $FAILED -gt 0 ]]; then
    exit 1
fi
