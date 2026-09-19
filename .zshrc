# ==============================================================================
# Zsh Configuration (macOS / General)
# ==============================================================================

# Oh-My-Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="candy"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting jsontools kube-ps1)

if [ -f "$ZSH/oh-my-zsh.sh" ]; then
    # shellcheck disable=SC1091
    source "$ZSH/oh-my-zsh.sh"
fi

# Default Editor & Vi Mode
export EDITOR="nvim"
export VISUAL="nvim"
set -o vi

# Base PATHs
export PATH="$HOME/.local/bin:$PATH"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# macOS / Homebrew environment
if [[ "$OSTYPE" == "darwin"* ]]; then
    if [ -f "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    if [ -d "/opt/homebrew/opt/qt/bin" ]; then
        export PATH="/opt/homebrew/opt/qt/bin:$PATH"
    fi
fi

# Load shared aliases
if [ -f "$HOME/.aliases" ]; then
    # shellcheck disable=SC1091
    source "$HOME/.aliases"
fi

# Kubeswitch (Switcher) integration
if command -v switcher >/dev/null 2>&1; then
    # shellcheck disable=SC1090
    source <(switcher init zsh)
fi

# Zoxide integration
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck disable=SC1091
    source "$NVM_DIR/nvm.sh"
fi
if [ -s "$NVM_DIR/bash_completion" ]; then
    # shellcheck disable=SC1091
    source "$NVM_DIR/bash_completion"
fi

# Kube-ps1 Configuration
KUBE_PS1_PREFIX="["
KUBE_PS1_SUFFIX="] "
KUBE_PS1_DIVIDER="|"
KUBE_PS1_SYMBOL_ENABLE="false"

# Local overrides (untracked machine-specific customizations)
if [ -f "$HOME/.zshrc.local" ]; then
    # shellcheck disable=SC1091
    source "$HOME/.zshrc.local"
fi
