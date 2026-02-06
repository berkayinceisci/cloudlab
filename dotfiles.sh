#!/bin/bash

cd $HOME/cloudlab

# stow
if ! command -v stow &>/dev/null; then
    echo "Installing stow..."
    wget https://ftp.gnu.org/gnu/stow/stow-2.3.1.tar.gz
    tar -xzf stow-2.3.1.tar.gz
    cd stow-2.3.1
    ./configure --prefix=$HOME/.local
    make
    make install
    cd -
    rm -rf stow-2.3.1
else
    echo "stow already installed, skipping..."
fi

# dotfiles
if [ ! -d "$HOME/dotfiles" ]; then
    echo "Setting up dotfiles..."
    git clone git@github.com:berkayinceisci/dotfiles.git $HOME/dotfiles
    cd $HOME/dotfiles
    if ! ./install.sh; then
        echo "stow failed, removing dotfiles directory..."
        cd - >/dev/null
        rm -rf $HOME/dotfiles
        exit 1
    fi
    cd - >/dev/null
    # Add popos host key now that ~/.ssh/config defines it
    ssh-keyscan popos >> "$HOME/.ssh/known_hosts" 2>/dev/null
else
    echo "dotfiles already exist, skipping..."
fi
