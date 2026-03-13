#!/usr/bin/env bash
# Stow wrapper functions

# Detect repository root
get_repo_root() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    git rev-parse --show-toplevel 2>/dev/null || echo "$script_dir"
}


# Cleanup conflicts for a single unit
cleanup_conflicts_unit() {
    local package_dir="$1"
    local target_base="$2"
    local subdir="$3"

    local unit_root
    if [[ -z "$subdir" ]]; then
        unit_root="$package_dir"
    else
        unit_root="$package_dir/$subdir"
    fi

    if [[ ! -e "$unit_root" && ! -L "$unit_root" ]]; then
        return 0
    fi

    log_info "Cleaning conflicts (target: $target_base) for subdir: ${subdir:-.}"

    if [[ -z "$subdir" ]]; then
        # Top-level: iterate immediate children of package_dir, excluding .config subtree
        while IFS= read -r entry; do
            local name="${entry#$package_dir/}"
            [[ "$name" == ".config" ]] && continue
            [[ "$name" == ".config/"* ]] && continue

            local target="$HOME/$name"
            if [[ -e "$target" || -L "$target" ]]; then
                log_info "Removing: $target"
                if [[ -d "$target" && ! -L "$target" ]]; then
                    rm -rf "$target"
                else
                    rm -f "$target"
                fi
            fi
        done < <(find "$package_dir" -mindepth 1 -maxdepth 1 -print | sort -r)
    else
        # Child under .config: the subdir name (e.g., nvim) is the entry to delete
        local child_name="${subdir#.config/}"
        local target="$target_base/$child_name"
        if [[ -e "$target" || -L "$target" ]]; then
            log_info "Removing: $target"
            if [[ -d "$target" && ! -L "$target" ]]; then
                rm -rf "$target"
            else
                rm -f "$target"
            fi
        fi
    fi
}

# Build overrides array
build_overrides() {
    local repo_root="$1"
    local overrides_file="$repo_root/packages/linux-overrides.txt"
    local override_args=()

    if [[ -f "$overrides_file" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            override_args+=("--override" "$line")
        done < "$overrides_file"
    fi

    printf '%s\n' "${override_args[@]}"
}

# Simulate stow for a unit
stow_simulate_unit() {
    local repo_root="$1"
    local package="$2"
    local target_base="$3"
    local subdir="$4"
    local override_args=("${@:5}")

    local package_dir="$repo_root/$package"
    local dir_arg
    local patterns

    if [[ -z "$subdir" ]]; then
        dir_arg="--dir=$package_dir"
        patterns=(".")
        # Exclude .config subtree from top-level stow
        override_args+=(--exclude ".config")
    else
        dir_arg="--dir=$package_dir/.config"
        patterns=("${subdir#.config/}")
    fi

    (
        cd "$repo_root"
        stow -t "$target_base" --simulate "${override_args[@]}" "${patterns[@]}"
    )
}

# Execute stow for a unit
stow_execute_unit() {
    local repo_root="$1"
    local package="$2"
    local target_base="$3"
    local subdir="$4"
    local override_args=("${@:5}")

    local package_dir="$repo_root/$package"
    local dir_arg
    local patterns

    if [[ -z "$subdir" ]]; then
        dir_arg="--dir=$package_dir"
        patterns=(".")
        override_args+=(--exclude ".config")
    else
        dir_arg="--dir=$package_dir/.config"
        patterns=("${subdir#.config/}")
    fi

    (
        cd "$repo_root"
        if stow -t "$target_base" --verbose "${override_args[@]}" "${patterns[@]}"; then
            log_success "Stowed: $package (subdir: ${subdir:-.})"
            return 0
        else
            log_error "Stow failed: $package (subdir: ${subdir:-.})"
            return 1
        fi
    )
}

# Main workflow
stow_packages() {
    local packages=("$@")
    local repo_root="$(get_repo_root)"
    local units=()

    # Validate repo
    if [[ ! -d "$repo_root/.git" ]] && [[ ! -d "$repo_root/common" ]]; then
        log_warn "Not a dotfiles repo: $repo_root"
        if ! confirm "Continue anyway?"; then
            return 1
        fi
    fi

    # Build units
    for pkg in "${packages[@]}"; do
        local package_dir="$repo_root/$pkg"
        if [[ ! -d "$package_dir" ]]; then
            log_warn "Skipping missing package: $package_dir"
            continue
        fi
        # Top-level unit
        units+=("$pkg ''")
        # .config children
        if [[ -d "$package_dir/.config" ]]; then
            while IFS= read -r child; do
                units+=("$pkg .config/$child")
            done < <(find "$package_dir/.config" -mindepth 1 -maxdepth 1 -exec basename {} \; | sort)
        fi
    done

    if [[ ${#units[@]} -eq 0 ]]; then
        log_warn "No units to stow"
        return 1
    fi

    # Build overrides once
    local override_arr=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && override_arr+=("$line")
    done < <(build_overrides "$repo_root")

    # Cleanup for all units
    log_info "Cleaning up existing conflicts..."
    for unit in "${units[@]}"; do
        local pkg subdir
        read -r pkg subdir <<< "$unit"
        if [[ -z "$subdir" ]]; then
            cleanup_conflicts_unit "$repo_root/$pkg" "$HOME" ""
        else
            cleanup_conflicts_unit "$repo_root/$pkg" "$HOME/.config" "$subdir"
        fi
    done

    # Simulation
    log_info "Simulation:"
    for unit in "${units[@]}"; do
        local pkg subdir
        read -r pkg subdir <<< "$unit"
        if ! stow_simulate_unit "$repo_root" "$pkg" "$HOME" "$subdir" "${override_arr[@]}"; then
            log_error "Simulation failed for $pkg ($subdir)"
            return 1
        fi
    done

    # Prompt
    echo ""
    if ! confirm "Apply all symlinks? (y/N)"; then
        log_info "Stow aborted"
        return 0
    fi

    # Execution
    log_info "Applying stow..."
    local failed_units=()
    for unit in "${units[@]}"; do
        local pkg subdir
        read -r pkg subdir <<< "$unit"
        if ! stow_execute_unit "$repo_root" "$pkg" "$HOME" "$subdir" "${override_arr[@]}"; then
            failed_units+=("$pkg:$subdir")
        fi
    done

    if [[ ${#failed_units[@]} -gt 0 ]]; then
        log_error "Failed units: ${failed_units[*]}"
        return 1
    fi

    log_success "All stow units applied"
    return 0
}
