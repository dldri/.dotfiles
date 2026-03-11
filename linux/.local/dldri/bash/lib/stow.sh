#!/usr/bin/env bash
# Stow wrapper functions

# Detect repository root
get_repo_root() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    git rev-parse --show-toplevel 2>/dev/null || echo "$script_dir"
}

# Simulate stow operation
stow_simulate() {
    local repo_root="$(get_repo_root)"
    local packages=("$@")

    log_info "Stow simulation (dry-run)"
    log_info "Target: \$HOME"
    log_info "Packages: ${packages[*]}"
    echo ""

    (
        cd "$repo_root"
        stow -t "$HOME" --simulate "${packages[@]}"
    )
}

# Execute stow operation
stow_execute() {
    local repo_root="$(get_repo_root)"
    local packages=("$@")

    log_info "Executing stow..."
    (
        cd "$repo_root"
        if stow -t "$HOME" --verbose "${packages[@]}"; then
            log_success "Stow completed successfully"
            return 0
        else
            log_error "Stow encountered errors (some files may have conflicted)"
            return 1
        fi
    )
}

# Full stow workflow: simulate, prompt, execute
stow_packages() {
    local packages=("$@")
    local repo_root="$(get_repo_root)"

    # Check we're in a git repo or valid dotfiles directory
    if [[ ! -d "$repo_ROOT/.git" ]] && [[ ! -d "$repo_root/common" ]]; then
        log_warn "Does not appear to be a dotfiles repository: $repo_root"
        if ! confirm "Continue anyway?"; then
            return 1
        fi
    fi

    # Run simulation
    stow_simulate "${packages[@]}"

    # Prompt for confirmation
    echo ""
    if ! confirm "Apply these symlinks? (y/N)"; then
        log_info "Stow aborted by user"
        return 0
    fi

    # Execute
    stow_execute "${packages[@]}"
}
