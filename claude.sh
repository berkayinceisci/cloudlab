#!/bin/bash

# Restore Claude Code credentials (avoids manual browser auth)
mkdir -p "$HOME/.claude"
echo "Decrypting Claude Code credentials (enter passphrase)..."
age -d -o "$HOME/.claude/.credentials.json" "$HOME/cloudlab/keys/claude_credentials.age"
chmod 600 "$HOME/.claude/.credentials.json"
