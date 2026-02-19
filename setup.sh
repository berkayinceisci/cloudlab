#!/bin/bash

if [ -z "$TMUX" ]; then
    echo "Error: Must be run inside a tmux session"
    exit 1
fi

mkdir -p $HOME/.local
export PATH="$HOME/.local/bin:$PATH"

./ssh_keys.sh   # asks for user input, sets up private/public ssh keys for cloudlab
./setup_disks.sh

./root_packages.sh
./nonroot_packages.sh

./benchmarks.sh

./kernels.sh
./update_grub.sh

./settings.sh
./crontab.sh
