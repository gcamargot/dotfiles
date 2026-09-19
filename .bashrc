# ==============================================================================
# Bash Configuration (Linux / General)
# ==============================================================================

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Shell behavior & history
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=5000
HISTFILESIZE=10000
shopt -s checkwinsize

# Default Editor & Vi Mode
export EDITOR="nvim"
export VISUAL="nvim"
set -o vi

# Base PATHs
export PATH="$HOME/.local/bin:$PATH"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# Load shared aliases
if [ -f "$HOME/.aliases" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.aliases"
fi

# Kubeswitch (Switcher) integration
if command -v switcher >/dev/null 2>&1; then
    # shellcheck disable=SC1090
    source <(switcher init bash)
fi

# Zoxide integration
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck disable=SC1091
    . "$NVM_DIR/nvm.sh"
fi
if [ -s "$NVM_DIR/bash_completion" ]; then
    # shellcheck disable=SC1091
    . "$NVM_DIR/bash_completion"
fi

# Git branch parser for custom PS1
parse_git_branch() {
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        local branch
        branch=$(git branch --show-current 2>/dev/null)
        if [ -z "$branch" ]; then
            branch=$(git rev-parse --short HEAD 2>/dev/null)
        fi
        if [ -n "$branch" ]; then
            printf " \001\033[01;35m\002(%s)\001\033[00m\002" "$branch"
        fi
    fi
}

# Prompt
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$(parse_git_branch)\$ '

# Local overrides (untracked machine-specific customizations)
if [ -f "$HOME/.bashrc.local" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.bashrc.local"
fi

# Periodic dotfiles update check
if [ -f "$HOME/dotfiles/check_updates.sh" ]; then
    # shellcheck disable=SC1091
    . "$HOME/dotfiles/check_updates.sh"
fi
