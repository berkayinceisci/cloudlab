#!/bin/bash

if [ -z "$TMUX" ]; then
    echo "Error: Must be run inside a tmux session"
    exit 1
fi

mkdir -p ~/.local
export PATH="$HOME/.local/bin:$PATH"

./ssh_keys.sh
./dotfiles.sh
./nonroot_packages.sh
./root_packages.sh
./benchmarks.sh
./settings.sh

# commands expecting user input
atuin login && atuin sync
