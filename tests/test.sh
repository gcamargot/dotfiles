#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Test Suite
# Validates syntax, configuration validity, and installer dry-run
# ==============================================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

ERRORS=0

pass() {
    echo "  [PASS] $1"
}

fail() {
    echo "  [FAIL] $1"
    ERRORS=$((ERRORS + 1))
}

info() {
    echo "ℹ️  $1"
}

echo "=================================================="
echo "🧪 Running Dotfiles Verification Tests"
echo "=================================================="

# 1. Test Bash Syntax
info "Checking Bash syntax..."
for file in .aliases .bashrc install.sh tests/test.sh; do
    if [ -f "$file" ]; then
        if bash -n "$file"; then
            pass "bash -n $file"
        else
            fail "Syntax error in $file"
        fi
    fi
done

# 2. Test Zsh Syntax (if zsh is available)
if command -v zsh >/dev/null 2>&1; then
    info "Checking Zsh syntax..."
    for file in .zshrc .aliases; do
        if [ -f "$file" ]; then
            if zsh -n "$file"; then
                pass "zsh -n $file"
            else
                fail "Zsh syntax error in $file"
            fi
        fi
    done
else
    echo "  [SKIP] zsh not installed locally, skipping zsh syntax check."
fi

# 3. Test ShellCheck (if shellcheck is available)
if command -v shellcheck >/dev/null 2>&1; then
    info "Running ShellCheck..."
    for file in .aliases .bashrc install.sh tests/test.sh; do
        if [ -f "$file" ]; then
            if shellcheck -s bash "$file"; then
                pass "shellcheck $file"
            else
                fail "ShellCheck issues in $file"
            fi
        fi
    done
else
    echo "  [SKIP] shellcheck not installed locally, skipping linting."
fi

# 4. Test Neovim Configuration (Headless)
info "Checking Neovim configuration loading..."
NVIM_BIN="$(command -v nvim || echo "$HOME/.local/bin/nvim")"
if [ -x "$NVIM_BIN" ]; then
    if "$NVIM_BIN" --headless -u "$REPO_DIR/.config/nvim/init.lua" "+qa" 2>&1; then
        pass "Neovim headless config loaded cleanly"
    else
        fail "Neovim failed to load config"
    fi
else
    echo "  [SKIP] nvim executable not found, skipping Neovim headless check."
fi

# 5. Test Installer Dry-Run
info "Testing installer script in dry-run mode..."
if ./install.sh --dry-run >/dev/null; then
    pass "./install.sh --dry-run"
else
    fail "./install.sh --dry-run failed"
fi

echo "=================================================="
if [ "$ERRORS" -eq 0 ]; then
    echo "✅ All tests passed successfully!"
    exit 0
else
    echo "❌ $ERRORS test(s) failed."
    exit 1
fi
