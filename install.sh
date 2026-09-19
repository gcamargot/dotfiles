#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Installer Script
# Safely creates symlinks with backups and supports dry-run mode
# ==============================================================================

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --dry-run)
            DRY_RUN=true
            echo "🔍 DRY RUN MODE: No files will be changed or linked."
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Usage: ./install.sh [--dry-run]"
            exit 1
            ;;
    esac
done

link_file() {
    local src="$1"
    local dest="$2"

    if [ -L "$dest" ] && [ "$(readlink -f "$dest" 2>/dev/null || readlink "$dest")" = "$src" ]; then
        echo "✓ Already linked: $dest -> $src"
        return 0
    fi

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "[dry-run] Would backup $dest to $BACKUP_DIR/"
        else
            mkdir -p "$BACKUP_DIR"
            echo "📦 Backing up $dest to $BACKUP_DIR/"
            mv "$dest" "$BACKUP_DIR/"
        fi
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "[dry-run] Would link $src -> $dest"
    else
        mkdir -p "$(dirname "$dest")"
        ln -sf "$src" "$dest"
        echo "🔗 Linked $src -> $dest"
    fi
}

echo "🚀 Installing Dotfiles from $DOTFILES_DIR"

# Common dotfiles
link_file "$DOTFILES_DIR/.aliases" "$HOME/.aliases"
link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim"

# OS / Shell specific links
if [[ "$OSTYPE" == "darwin"* ]]; then
    link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
    echo "🍏 Configured for macOS"
else
    link_file "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
    echo "🐧 Configured for Linux"
fi

if [ "$DRY_RUN" = false ]; then
    echo "✨ Dotfiles installation completed successfully!"
    if [ -d "$BACKUP_DIR" ]; then
        echo "⚠️ Previous configurations were backed up in: $BACKUP_DIR"
    fi
else
    echo "✨ Dry run completed without errors."
fi
