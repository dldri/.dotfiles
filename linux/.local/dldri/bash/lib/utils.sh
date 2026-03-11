#!/usr/bin/env bash
# Shared utility functions

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info()   { echo -e "${NC}[INFO] $*${NC}"; }
log_success(){ echo -e "${GREEN}[✓] $*${NC}"; }
log_warn()   { echo -e "${YELLOW}[!] $*${NC}"; }
log_error()  { echo -e "${RED}[✗] $*${NC}"; }

# Check if a package is installed in pacman database
is_installed() {
    local pkg="$1"
    if pacman -Q "$pkg" &>/dev/null; then
        return 0  # true - installed
    else
        return 1  # false - not installed
    fi
}

# Ensure we have sudo privileges
require_sudo() {
    if ! sudo -v; then
        log_error "sudo privileges required. Please run with sudo or configure sudo."
        exit 1
    fi
}

# Confirm action with user
confirm() {
    local prompt="$1 (y/N): "
    read -r -p "$prompt" response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}
