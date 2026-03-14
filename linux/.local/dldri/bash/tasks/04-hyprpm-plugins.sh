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

# Read desired plugins from list file
if [[ ! -f "$PLUGINS_LIST" ]]; then
    log_warn "Plugins list not found: $PLUGINS_LIST - skipping"
    exit 0
fi

declare -A desired_plugins=()  # name -> uri
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
declare -A installed_plugins=()  # name -> enabled status (true/false/other)
declare -A enabled_plugins=()    # name -> true (only for enabled)

current_plugin=""
while IFS= read -r line || [[ -n "$line" ]]; do
    # Extract plugin name from lines containing "Plugin <name>"
    if [[ $line =~ Plugin[[:space:]]+([^[:space:]]+) ]]; then
        current_plugin="${BASH_REMATCH[1]}"
    # Extract enabled status from lines containing "enabled: <status>"
    elif [[ $line =~ enabled:[[:space:]]*(true|false) ]] && [[ -n "$current_plugin" ]]; then
        status="${BASH_REMATCH[1]}"
        installed_plugins["$current_plugin"]="$status"
        if [[ "$status" == "true" ]]; then
            enabled_plugins["$current_plugin"]="true"
        fi
        current_plugin=""
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

# Track which plugins we enabled during add phase to avoid double-counting
declare -A enabled_during_add=()

# 1. Remove plugins not in desired list
for plugin in "${to_remove[@]}"; do
    log_info "Removing plugin: $plugin"
    # Disable first if enabled, since hyprpm remove fails on enabled plugins
    if [[ "${enabled_plugins[$plugin]:-}" == "true" ]]; then
        log_info "Disabling plugin: $plugin"
        hyprpm disable "$plugin" 2>/dev/null || true
    fi
    if hyprpm remove "$plugin" 2>/dev/null; then
        log_success "  Removed $plugin"
        ((REMOVED++))
    else
        log_warn "  Failed to remove $plugin (may not exist)"
        ((FAILED++))
    fi
done

# 2. Add new plugins (those not yet installed)
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
    # Skip if we already enabled it during add phase
    if [[ -n "${enabled_during_add[$plugin]:-}" ]]; then
        log_info "Plugin $plugin already enabled during add phase, skipping"
        continue
    fi
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

log_info "Reloading Hyprland plugins..."
if hyprpm reload; then
    log_success "Plugins reloaded"
else
    log_warn "Reload failed (Hyprland may not be running)"
fi

if [[ $FAILED -gt 0 ]]; then
    exit 1
fi
