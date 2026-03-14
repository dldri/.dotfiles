#!/usr/bin/env bash
# 04-hyprpm-plugins.sh - Sync Hyprland plugins via hyprpm to match packages/hyprland-plugins.txt

set -euo pipefail

# Get repository root via git
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || { echo "Error: Not in a git repository" >&2; exit 1; })"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../lib/utils.sh"
source "$SCRIPT_DIR/../lib/platform.sh"

PLUGINS_LIST="$REPO_ROOT/packages/hyprland-plugins.txt"

log_info "Syncing Hyprland plugins via hyprpm..."

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

# Read desired plugins from list file
if [[ ! -f "$PLUGINS_LIST" ]]; then
    log_warn "Plugins list not found: $PLUGINS_LIST - skipping"
    exit 0
fi

declare -A desired_plugins  # name -> uri
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^# ]] && continue
    [[ -z "$line" ]] && continue
    # Extract plugin name from URI (last path segment, strip .git if present)
    uri="$line"
    name="$(basename "$uri")"
    name="${name%.git}"
    desired_plugins["$name"]="$uri"
done < "$PLUGINS_LIST"

log_info "Desired plugins: ${#desired_plugins[@]}"

# Get currently installed plugins and their status
declare -A installed_plugins  # name -> enabled status (true/false/other)
declare -A enabled_plugins    # name -> true (only for enabled)

current_plugin=""
while IFS= read -r line || [[ -n "$line" ]]; do
    # Match plugin name line: "│ Plugin <name>"
    if [[ "$line" =~ ^[[:space:]]*[\|][[:space:]]*Plugin[[:space:]]+(.+)$ ]]; then
        current_plugin="${BASH_REMATCH[1]}"
    # Match enabled status line: "└─ enabled: <status>"
    elif [[ "$line" =~ ^[[:space:]]*[\└─][[:space:]]*enabled:[[:space:]]*(.+)$ ]]; then
        if [[ -n "$current_plugin" ]]; then
            status="${BASH_REMATCH[1]}"
            installed_plugins["$current_plugin"]="$status"
            if [[ "$status" == "true" ]]; then
                enabled_plugins["$current_plugin"]="true"
            fi
            current_plugin=""
        fi
    fi
done < <(hyprpm list 2>/dev/null || true)

log_info "Currently installed: ${#installed_plugins[@]} (enabled: ${#enabled_plugins[@]})"

# Compute differences
to_remove=()
to_add=()
to_enable=()

# Remove: installed but not desired
for plugin in "${!installed_plugins[@]}"; do
    if [[ -z "${desired_plugins[$plugin]:-}" ]]; then
        to_remove+=("$plugin")
    fi
done

# Add and Enable: desired but not installed
for plugin in "${!desired_plugins[@]}"; do
    if [[ -z "${installed_plugins[$plugin]:-}" ]]; then
        to_add+=("$plugin")
        to_enable+=("$plugin")
    elif [[ -z "${enabled_plugins[$plugin]:-}" ]]; then
        # Installed but not enabled
        to_enable+=("$plugin")
    fi
done

log_info "Plan: Remove ${#to_remove[@]}, Add ${#to_add[@]}, Enable ${#to_enable[@]}"

# Execute operations
REMOVED=0
ADDED=0
ENABLED=0
SKIPPED=0
FAILED=0

# 1. Remove plugins not in desired list
for plugin in "${to_remove[@]}"; do
    log_info "Removing plugin: $plugin"
    if hyprpm remove "$plugin" 2>/dev/null; then
        log_success "  Removed $plugin"
        ((REMOVED++))
    else
        log_warn "  Failed to remove $plugin (may not exist)"
        ((FAILED++))
    fi
done

# 2. Add new plugins
for plugin in "${to_add[@]}"; do
    uri="${desired_plugins[$plugin]}"
    log_info "Adding plugin: $plugin from $uri"
    if hyprpm add "$uri"; then
        log_success "  Added $plugin"
        ((ADDED++))
    else
        log_error "  Failed to add $plugin"
        ((FAILED++))
        continue
    fi
done

# 3. Enable plugins that should be enabled
for plugin in "${to_enable[@]}"; do
    log_info "Enabling plugin: $plugin"
    if hyprpm enable "$plugin"; then
        log_success "  Enabled $plugin"
        ((ENABLED++))
    else
        log_error "  Failed to enable $plugin"
        ((FAILED++))
    fi
done

# Count already correct plugins (desired, installed, enabled)
for plugin in "${!desired_plugins[@]}"; do
    if [[ -n "${installed_plugins[$plugin]:-}" ]] && [[ -n "${enabled_plugins[$plugin]:-}" ]]; then
        ((SKIPPED++))
    fi
done

log_success "Hyprpm sync complete. Removed: $REMOVED, Added: $ADDED, Enabled: $ENABLED, Already correct: $SKIPPED, Failed: $FAILED"

if [[ $FAILED -gt 0 ]]; then
    exit 1
fi
