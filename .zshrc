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
alias shutdown='systemctl poweroff'
alias wifi='nmtui'
alias lock='hyprlock'
alias clock='tty-clock'

# Fastfetch
alias ff='fastfetch'

# Eza (ls replacement)
alias ls='eza -a --icons=always'
alias ll='eza -al --icons=always'
alias lt='eza -a --tree --level=1 --icons=always'

# System
alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'

