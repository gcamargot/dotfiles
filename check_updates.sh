#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Update Checker
# Checks for remote updates on GitHub with throttling to prevent terminal lag.
# ==============================================================================

check_for_updates() {
    # Only run in interactive shells
    case $- in
        *i*) ;;
        *) return 0 ;;
    esac

    DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
    [ -d "$DOTFILES_DIR/.git" ] || return 0

    local force=false
    for arg in "$@"; do
        if [ "$arg" = "--force" ]; then
            force=true
        fi
    done

    # 12 hours check interval (43200 seconds)
    local check_interval=43200
    local last_check_file="$DOTFILES_DIR/.last_update_check"
    local current_time
    current_time=$(date +%s)

    if [ "$force" = false ] && [ -f "$last_check_file" ]; then
        local last_check
        last_check=$(cat "$last_check_file" 2>/dev/null || echo 0)
        if [[ "$last_check" =~ ^[0-9]+$ ]]; then
            if [ $((current_time - last_check)) -lt "$check_interval" ]; then
                return 0
            fi
        fi
    fi

    # Update timestamp
    echo "$current_time" > "$last_check_file" 2>/dev/null || true

    # Silent fetch from remote main
    if git -C "$DOTFILES_DIR" fetch --quiet origin main 2>/dev/null; then
        local local_commit remote_commit
        local_commit=$(git -C "$DOTFILES_DIR" rev-parse HEAD 2>/dev/null)
        remote_commit=$(git -C "$DOTFILES_DIR" rev-parse origin/main 2>/dev/null)

        if [ -n "$local_commit" ] && [ -n "$remote_commit" ] && [ "$local_commit" != "$remote_commit" ]; then
            local behind
            behind=$(git -C "$DOTFILES_DIR" rev-list --count "HEAD..origin/main" 2>/dev/null || echo 0)
            if [ "$behind" -gt 0 ]; then
                echo ""
                echo "Dotfiles: Hay $behind nuevo(s) commit(s) en GitHub."
                printf "Deseas actualizar ahora con git pull? [y/N]: "
                local response
                read -r response
                if [[ "$response" =~ ^[Yy]$ ]]; then
                    git -C "$DOTFILES_DIR" pull --ff-only && echo "Dotfiles actualizados correctamente."
                fi
                echo ""
            fi
        fi
    fi
}

check_for_updates "$@"
