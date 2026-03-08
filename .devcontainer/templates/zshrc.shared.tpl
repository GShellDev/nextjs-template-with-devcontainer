export ZSH="__ZSH_DIR__"

ZSH_THEME="__ZSH_THEME__"

plugins=(__ZSH_PLUGINS__)

source "$ZSH/oh-my-zsh.sh"

[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

alias cls="clear"