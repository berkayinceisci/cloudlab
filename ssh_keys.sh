#!/bin/bash

if ! command -v age &>/dev/null; then
    AGE_VERSION="v1.2.1"
    wget -qO /tmp/age.tar.gz "https://dl.filippo.io/age/${AGE_VERSION}?for=linux/amd64"
    tar -xzf /tmp/age.tar.gz -C /tmp
    sudo cp /tmp/age/age /tmp/age/age-keygen /usr/local/bin/
    rm -rf /tmp/age /tmp/age.tar.gz
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_DIR="$SCRIPT_DIR/keys"

if [[ ! -f "$KEY_DIR/id_ed25519.age" ]] || [[ ! -f "$KEY_DIR/id_ed25519.pub" ]]; then
    echo "Error: Key pair not found in $KEY_DIR"
    echo "Expected id_ed25519.age and id_ed25519.pub"
    exit 1
fi

mkdir -p "$HOME/.ssh"

# Decrypt private key (asks for age passphrase)
echo "Decrypting SSH private key (enter passphrase)..."
age -d -o "$HOME/.ssh/id_ed25519" "$KEY_DIR/id_ed25519.age"

cp "$KEY_DIR/id_ed25519.pub" "$HOME/.ssh/id_ed25519.pub"
chmod 700 "$HOME/.ssh"
chmod 600 "$HOME/.ssh/id_ed25519"
chmod 644 "$HOME/.ssh/id_ed25519.pub"

ssh-keyscan github.com >> "$HOME/.ssh/known_hosts"
