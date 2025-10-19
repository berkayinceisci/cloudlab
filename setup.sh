#!/bin/bash

if [ -z "$TMUX" ]; then
    echo "Error: Must be run inside a tmux session"
    exit 1
fi

./ssh_keys.sh
./nonroot_packages.sh
./root_packages.sh
./benchmarks.sh
./settings.sh
