#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_DIR="$SCRIPT_DIR/keys"

if [[ ! -f "$KEY_DIR/id_ed25519" ]] || [[ ! -f "$KEY_DIR/id_ed25519.pub" ]]; then
    echo "Error: Key pair not found in $KEY_DIR"
    echo "Place your passphrase-protected id_ed25519 and id_ed25519.pub there first."
    exit 1
fi

mkdir -p "$HOME/.ssh"
cp "$KEY_DIR/id_ed25519" "$HOME/.ssh/id_ed25519"
cp "$KEY_DIR/id_ed25519.pub" "$HOME/.ssh/id_ed25519.pub"
chmod 700 "$HOME/.ssh"
chmod 600 "$HOME/.ssh/id_ed25519"
chmod 644 "$HOME/.ssh/id_ed25519.pub"

eval "$(ssh-agent -s)"
ssh-add "$HOME/.ssh/id_ed25519"

ssh-keyscan github.com >> "$HOME/.ssh/known_hosts"
