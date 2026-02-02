#!/bin/bash

if [ -z "$TMUX" ]; then
    echo "Error: Must be run inside a tmux session"
    exit 1
fi

mkdir -p $HOME/.local
export PATH="$HOME/.local/bin:$PATH"

./ssh_keys.sh   # asks for user input
./root_packages.sh
./nonroot_packages.sh

sudo chown -R $USER /tdata
./benchmarks.sh
./kernels.sh
./update_grub.sh

./settings.sh
./crontab.sh
