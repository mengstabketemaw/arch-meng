# =====================================================
#  ENVIRONMENT
# =====================================================
export EDITOR=nvim
export PATH=$PATH:$HOME/.cargo/bin:$HOME/.local/bin
export ZSH="$HOME/.oh-my-zsh"
export PATH=/home/meng/.opencode/bin:$PATH
export PATH="$HOME/.npm-global/bin:$PATH"

# =====================================================
#  OH-MY-ZSH PLUGINS
# =====================================================

plugins=(
    sudo                  # Double-Esc to prepend sudo
    web-search            # google/wiki/yt query from terminal
    zsh-autosuggestions   # History-based autosuggestions while typing
    fast-syntax-highlighting  # Real-time syntax coloring
    copyfile              # copyfile file.txt -> copies content to clipboard
    copybuffer            # Ctrl-O copies current line to clipboard
    dirhistory            # Alt-Left/Right to navigate dir history
)

source $ZSH/oh-my-zsh.sh

# Ctrl-Space to accept autosuggestion
bindkey '^ ' autosuggest-accept

# =====================================================
#  FUZZY FINDER (FZF)
# =====================================================

source <(fzf --zsh)

# =====================================================
#  ZOXIDE (smart cd)
# =====================================================

eval "$(zoxide init zsh --cmd cd)"

# =====================================================
#  PROMPT (oh-my-posh)
# =====================================================

eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/zen.toml)"

# =====================================================
#  ALIASES
# =====================================================

source /usr/share/nvm/init-nvm.sh

# Utils
alias c='clear'
alias v='$EDITOR'
alias vim='$EDITOR'
alias lock='hyprlock'

# Fastfetch
alias ff='fastfetch'

# Eza (ls replacement)
alias ls='eza -a --icons=always'
alias ll='eza -al --icons=always'
alias lt='eza -a --tree --level=1 --icons=always'

# System
alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'



# Added by Antigravity CLI installer
export PATH="/home/meng/.local/bin:$PATH"

. "$HOME/.local/share/../bin/env"


fuck() {
    if [ -z "$1" ]; then
        return 1
    fi

    echo "Nuking all processes on port $1..."
    
    # -k: kill, -n tcp: specifies the protocol, -s 9: forcefully kill immediately
    sudo fuser -k -n tcp "$1" || echo "No process found running on port $1."
}
