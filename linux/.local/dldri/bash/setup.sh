#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
DRY_RUN=0
SKIP_REMOVE=0
SKIP_INSTALL=0

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Setup script: remove unwanted packages and install needed ones"
    echo ""
    echo "Options:"
    echo "  --dry-run       Show what would be done without doing it"
    echo "  --skip-remove   Skip package removal step"
    echo "  --skip-install  Skip package installation step"
    echo "  --help          Show this help"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --skip-remove) SKIP_REMOVE=1 ;;
        --skip-install) SKIP_INSTALL=1 ;;
        --help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
    shift
done

# If both skipped, nothing to do
if [[ $SKIP_REMOVE -eq 1 && $SKIP_INSTALL -eq 1 ]]; then
    echo "Nothing to do. Both --skip-remove and --skip-install specified."
    exit 0
fi

# Confirmation
echo "========================================"
echo "Setup will:"
[[ $SKIP_REMOVE -eq 0 ]] && echo "  - Remove packages listed in packages/linux-remove.txt"
[[ $SKIP_INSTALL -eq 0 ]] && echo "  - Install packages listed in packages/linux.txt"
echo "========================================"
if [[ $DRY_RUN -eq 0 ]]; then
    read -p "Continue? (y/N): " -r confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
fi

# Execute steps
if [[ $SKIP_REMOVE -eq 0 ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "[DRY RUN] Would execute: $SCRIPT_DIR/remove-packages.sh"
    else
        "$SCRIPT_DIR/remove-packages.sh"
    fi
fi

if [[ $SKIP_INSTALL -eq 0 ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "[DRY RUN] Would execute: $SCRIPT_DIR/install-packages.sh"
    else
        "$SCRIPT_DIR/install-packages.sh"
    fi
fi

echo "========================================"
echo "Setup complete!"
