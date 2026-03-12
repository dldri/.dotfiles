#!/usr/bin/env bash
# Stow wrapper functions

# Detect repository root
get_repo_root() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    git rev-parse --show-toplevel 2>/dev/null || echo "$script_dir"
}

# Delete existing files/dirs that would conflict with stowing
# Forces overwrite: .dotfiles is SSOT
cleanup_conflicts() {
    local repo_root="$1"
    local package="$2"
    local package_dir="$repo_root/$package"
    
    if [[ ! -d "$package_dir" ]]; then
        return 0
    fi
    
    log_info "Cleaning up conflicts for package: $package"
    
    # Find all files and directories in the package, excluding .stow* and .git
    # Use -depth to process children before parents (needed for rm -rf on dirs)
    while IFS= read -r item; do
        # Skip metadata and hidden stow files
        [[ "$(basename "$item")" =~ ^\.stow ]] && continue
        [[ "$(basename "$item")" == ".git" ]] && continue
        
        # Compute target path relative to HOME
        local rel_path="${item#$package_dir/}"
        local target="$HOME/$rel_path"
        
        if [[ -e "$target" || -L "$target" ]]; then
            log_info "Removing: $target"
            if [[ -d "$target" && ! -L "$target" ]]; then
                rm -rf "$target"
            else
                rm -f "$target"
            fi
        fi
    done < <(find "$package_dir" -mindepth 1 -print | sort -r)
}

# Simulate stow operation
stow_simulate() {
    local repo_root="$(get_repo_root)"
    local packages=("$@")
    local overrides_file="$repo_root/packages/linux-overrides.txt"
    local override_args=()

    log_info "Stow simulation (dry-run)"
    log_info "Target: \$HOME"
    log_info "Packages: ${packages[*]}"
    echo ""

    # Load dynamic overrides if file exists
    if [[ -f "$overrides_file" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip blank lines and comments
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            override_args+=("--override" "$line")
        done < "$overrides_file"
    fi

    (
        cd "$repo_root"
        stow -t "$HOME" --simulate "${override_args[@]}" "${packages[@]}"
    )
}

# Execute stow operation
stow_execute() {
    local repo_root="$(get_repo_root)"
    local packages=("$@")
    local overrides_file="$repo_root/packages/linux-overrides.txt"
    local override_args=()

    log_info "Executing stow..."

    # Load dynamic overrides if file exists
    if [[ -f "$overrides_file" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip blank lines and comments
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            override_args+=("--override" "$line")
        done < "$overrides_file"

        if [[ ${#override_args[@]} -gt 0 ]]; then
            log_info "Applying ${#override_args[@]} override(s)"
        fi
    fi

    (
        cd "$repo_root"
        if stow -t "$HOME" --verbose "${override_args[@]}" "${packages[@]}"; then
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
    if [[ ! -d "$repo_root/.git" ]] && [[ ! -d "$repo_root/common" ]]; then
        log_warn "Does not appear to be a dotfiles repository: $repo_root"
        if ! confirm "Continue anyway?"; then
            return 1
        fi
    fi

    # Cleanup existing conflicts before stowing (.dotfiles as SSOT)
    for pkg in "${packages[@]}"; do
        cleanup_conflicts "$repo_root" "$pkg"
    done

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
