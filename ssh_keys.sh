#!/bin/bash

if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "Generating SSH key for Git..."
    email="inceisciberkay@gmail.com"
    echo "Using email: $email"
    ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519 -N ""
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519
    echo "===================================================="
    echo "Your SSH public key (copy this to GitHub/GitLab):"
    echo "===================================================="
    cat ~/.ssh/id_ed25519.pub
    echo "===================================================="
    echo "Add this key to -- https://github.com/settings/ssh/new -- then press Enter to continue..."
    read dummy
fi

ssh-keyscan github.com >> ~/.ssh/known_hosts

if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ""
fi
