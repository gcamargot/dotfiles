#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Update Checker
# Checks for remote updates on GitHub with throttling to prevent terminal lag.
# ==============================================================================

# Only run in interactive shells
case $- in
    *i*) ;;
    *) return 0 2>/dev/null || exit 0 ;;
esac

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
[ -d "$DOTFILES_DIR/.git" ] || return 0 2>/dev/null || exit 0

FORCE=false
for arg in "$@"; do
    if [ "$arg" = "--force" ]; then
        FORCE=true
    fi
done

# 12 hours check interval (43200 seconds)
CHECK_INTERVAL=43200
LAST_CHECK_FILE="$DOTFILES_DIR/.last_update_check"
CURRENT_TIME=$(date +%s)

if [ "$FORCE" = false ] && [ -f "$LAST_CHECK_FILE" ]; then
    LAST_CHECK=$(cat "$LAST_CHECK_FILE" 2>/dev/null || echo 0)
    if [[ "$LAST_CHECK" =~ ^[0-9]+$ ]]; then
        if [ $((CURRENT_TIME - LAST_CHECK)) -lt "$CHECK_INTERVAL" ]; then
            return 0 2>/dev/null || exit 0
        fi
    fi
fi

# Update timestamp
echo "$CURRENT_TIME" > "$LAST_CHECK_FILE" 2>/dev/null || true

# Silent fetch from remote main
if git -C "$DOTFILES_DIR" fetch --quiet origin main 2>/dev/null; then
    LOCAL=$(git -C "$DOTFILES_DIR" rev-parse HEAD 2>/dev/null)
    REMOTE=$(git -C "$DOTFILES_DIR" rev-parse origin/main 2>/dev/null)

    if [ -n "$LOCAL" ] && [ -n "$REMOTE" ] && [ "$LOCAL" != "$REMOTE" ]; then
        BEHIND=$(git -C "$DOTFILES_DIR" rev-list --count "HEAD..origin/main" 2>/dev/null || echo 0)
        if [ "$BEHIND" -gt 0 ]; then
            echo ""
            echo "Dotfiles: Hay $BEHIND nuevo(s) commit(s) en GitHub."
            printf "Deseas actualizar ahora con git pull? [y/N]: "
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                git -C "$DOTFILES_DIR" pull --ff-only && echo "Dotfiles actualizados correctamente."
            fi
            echo ""
        fi
    fi
fi
