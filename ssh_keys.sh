#!/bin/bash

if [ ! -f $HOME/.ssh/id_ed25519 ]; then
    echo "Generating SSH key for Git..."
    email="inceisciberkay@gmail.com"
    echo "Using email: $email"
    ssh-keygen -t ed25519 -C "$email" -f $HOME/.ssh/id_ed25519 -N ""
    eval "$(ssh-agent -s)"
    ssh-add $HOME/.ssh/id_ed25519
    echo "===================================================="
    echo "Your SSH public key (copy this to GitHub/GitLab):"
    echo "===================================================="
    cat $HOME/.ssh/id_ed25519.pub
    echo "===================================================="
    echo "Add this key to -- https://github.com/settings/ssh/new -- then press Enter to continue..."
    read dummy
fi

ssh-keyscan github.com >> $HOME/.ssh/known_hosts

if [ ! -f $HOME/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -f $HOME/.ssh/id_rsa -N ""
fi
