#!/usr/bin/env bash
# bootstrap.sh - Main entry point for dotfiles setup

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/../.."

# Load libraries
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/platform.sh"

# Parse arguments
DRY_RUN=0
SKIP_CHECK=0
SKIP_CLEANUP=0
SKIP_PACKAGES=0
SKIP_POST=0
SKIP_HYPRPM_PLUGINS=0
SKIP_WEBAPPS=0

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Bootstrap script: full system setup with dependencies, packages, and dotfiles"
    echo ""
    echo "Options:"
    echo "  --dry-run              Show what would be done without doing it"
    echo "  --skip-check           Skip dependency checks (00)"
    echo "  --skip-cleanup         Skip package cleanup (01)"
    echo "  --skip-packages        Skip package installation (02)"
    echo "  --skip-post            Skip post-setup (03)"
    echo "  --skip-hyprpm-plugins  Skip hyprpm plugin setup (04)"
    echo "  --skip-webapps        Skip web app cleanup (05)"
    echo "  --help                Show this help"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --skip-check) SKIP_CHECK=1 ;;
        --skip-cleanup) SKIP_CLEANUP=1 ;;
        --skip-packages) SKIP_PACKAGES=1 ;;
        --skip-post) SKIP_POST=1 ;;
        --skip-hyprpm-plugins) SKIP_HYPRPM_PLUGINS=1 ;;
        --skip-webapps) SKIP_WEBAPPS=1 ;;
        --help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
    shift
done

# If all skipped, nothing to do
if [[ $SKIP_CHECK -eq 1 && $SKIP_CLEANUP -eq 1 && $SKIP_PACKAGES -eq 1 && $SKIP_POST -eq 1 && $SKIP_HYPRPM_PLUGINS -eq 1 && $SKIP_WEBAPPS -eq 1 ]]; then
    echo "Nothing to do. All steps skipped."
    exit 0
fi

# Print banner
echo "========================================"
echo "     Dotfiles Bootstrap"
echo "========================================"
echo "Repository: $REPO_ROOT"
echo "Started:    $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
echo ""

# Track overall timing
START_TIME=$(date +%s)
FAILED_TASKS=()

run_task() {
    local task_name="$1"
    local task_script="$2"
    local skip_flag="$3"

    if [[ $skip_flag -eq 1 ]]; then
        log_info "⏭  Skipping $task_name"
        return 0
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would run: $task_script"
        return 0
    fi

    log_info "▶  $task_name..."
    if "$task_script"; then
        log_success "✓ $task_name completed"
        return 0
    else
        log_error "✗ $task_name failed"
        FAILED_TASKS+=("$task_name")
        return 1
    fi
}

# Execute tasks in order
run_task "Dependency Check (00)"    "$SCRIPT_DIR/tasks/00-check-deps.sh"    $SKIP_CHECK
run_task "Package Cleanup (01)"    "$SCRIPT_DIR/tasks/01-cleanup.sh"      $SKIP_CLEANUP
run_task "Package Install (02)"    "$SCRIPT_DIR/tasks/02-packages.sh"     $SKIP_PACKAGES
run_task "Post-Setup (03)"         "$SCRIPT_DIR/tasks/03-post-setup.sh"   $SKIP_POST
run_task "Hyprpm Plugins (04)"     "$SCRIPT_DIR/tasks/04-hyprpm-plugins.sh" $SKIP_HYPRPM_PLUGINS
run_task "Web App Cleanup (05)"    "$SCRIPT_DIR/tasks/05-remove-webapps.sh"  $SKIP_WEBAPPS

# Calculate duration
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo "========================================"
echo "Bootstrap Summary"
echo "========================================"
echo "Completed: $(date '+%Y-%m-%d %H:%M:%S')"
printf "Duration:   %02d:%02d\n" $MINUTES $SECONDS
echo ""

if [[ ${#FAILED_TASKS[@]} -eq 0 ]]; then
    log_success "All tasks completed successfully!"
    echo ""
    echo "Next steps:"
    echo "  • Reload your shell: source ~/.bashrc (or ~/.zshrc)"
    echo "  • Sync Neovim plugins: nvim --headless +'Lazy! sync' +qa"
    echo "  • Reboot to start Hyprland (if installed)"
    exit 0
else
    log_error "The following tasks failed:"
    for task in "${FAILED_TASKS[@]}"; do
        echo "  ✗ $task"
    done
    echo ""
    echo "Please review the output above and correct issues, then re-run."
    exit 1
fi
