#!/usr/bin/env bash
# ==============================================================================
# Package Installer from requirements.txt
# Supports Homebrew (macOS/Linux) and APT (Ubuntu/Debian)
# ==============================================================================

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REQ_FILE="$DIR/requirements.txt"
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --dry-run)
            DRY_RUN=true
            echo "[dry-run] DRY RUN MODE: No packages will be installed."
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Usage: ./install_packages.sh [--dry-run]"
            exit 1
            ;;
    esac
done

if [ ! -f "$REQ_FILE" ]; then
    echo "Error: requirements file not found at $REQ_FILE"
    exit 1
fi

# Detect Package Manager
PKG_MGR=""
if [[ "$OSTYPE" == "darwin"* ]] || command -v brew >/dev/null 2>&1; then
    PKG_MGR="brew"
elif command -v apt-get >/dev/null 2>&1; then
    PKG_MGR="apt"
else
    echo "Error: Neither 'brew' nor 'apt-get' found on this system."
    exit 1
fi

echo "Detected package manager: $PKG_MGR"

PACKAGES_TO_INSTALL=()

while IFS= read -r raw_line || [ -n "$raw_line" ]; do
    # Strip carriage returns and comments
    line="$(echo "$raw_line" | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    if [[ -z "$line" ]] || [[ "$line" =~ ^# ]]; then
        continue
    fi

    if [[ "$line" == *"|"* ]]; then
        APT_PKG="$(echo "$line" | cut -d'|' -f2 | xargs)"
        BREW_PKG="$(echo "$line" | cut -d'|' -f3 | xargs)"
    else
        APT_PKG="$line"
        BREW_PKG="$line"
    fi

    TARGET_PKG=""
    if [ "$PKG_MGR" = "brew" ]; then
        TARGET_PKG="$BREW_PKG"
    elif [ "$PKG_MGR" = "apt" ]; then
        TARGET_PKG="$APT_PKG"
    fi

    if [ -n "$TARGET_PKG" ] && [ "$TARGET_PKG" != "-" ]; then
        PACKAGES_TO_INSTALL+=("$TARGET_PKG")
    fi
done < "$REQ_FILE"

echo "Packages to install (${#PACKAGES_TO_INSTALL[@]}): ${PACKAGES_TO_INSTALL[*]}"

if [ "$DRY_RUN" = true ]; then
    echo "[dry-run] Would execute: "
    if [ "$PKG_MGR" = "brew" ]; then
        echo "  brew install ${PACKAGES_TO_INSTALL[*]}"
    elif [ "$PKG_MGR" = "apt" ]; then
        echo "  sudo apt-get update && sudo apt-get install -y ${PACKAGES_TO_INSTALL[*]}"
    fi
    exit 0
fi

if [ "$PKG_MGR" = "brew" ]; then
    echo "Installing packages with Homebrew..."
    brew install "${PACKAGES_TO_INSTALL[@]}"
elif [ "$PKG_MGR" = "apt" ]; then
    echo "Updating apt cache and installing packages..."
    sudo apt-get update
    sudo apt-get install -y "${PACKAGES_TO_INSTALL[@]}"

    # Fallback for yq (mikefarah/yq) on Linux if not present
    if ! command -v yq >/dev/null 2>&1; then
        echo "Installing mikefarah/yq to ~/.local/bin/yq..."
        mkdir -p "$HOME/.local/bin"
        ARCH="$(uname -m)"
        YQ_BIN="yq_linux_amd64"
        if [ "$ARCH" = "aarch64" ]; then
            YQ_BIN="yq_linux_arm64"
        fi
        curl -sL "https://github.com/mikefarah/yq/releases/latest/download/${YQ_BIN}" -o "$HOME/.local/bin/yq"
        chmod +x "$HOME/.local/bin/yq"
    fi

    # Fallback for yaml-language-server on Linux if npm is available
    if ! command -v yaml-language-server >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
        echo "Installing yaml-language-server via npm..."
        npm install -g yaml-language-server
    fi
fi

echo "Package installation completed successfully!"
