#!/usr/bin/env bash

local tmp=$(mktemp -d)
git clone https://gist.github.com/964a68b39310c4205596aef40b2cdc8f.git "$tmp"
cp "$tmp/kali-linux.zsh-theme" "$ZSH/custom/themes/"

if grep -q '^ZSH_THEME=' "$HOME/.zshrc"; then
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="kali-linux"/' "$HOME/.zshrc"
    chsh -s
    rm -rf "$tmp"
else
    echo 'ZSH_THEME="kali-linux"' >> "$HOME/.zshrc"
    chsh -s zsh "$(whoami)"
    rm -rf "$tmp"
fi