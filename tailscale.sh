#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_DIR="$SCRIPT_DIR/keys"

# Install tailscale if not already installed
if ! command -v tailscale &>/dev/null; then
    curl -fsSL https://tailscale.com/install.sh | sh
fi

# Decrypt OAuth client credentials (don't expire, unlike auth keys)
if [[ ! -f "$KEY_DIR/tailscale_oauth.age" ]]; then
    echo "Error: tailscale_oauth.age not found in $KEY_DIR"
    echo "Expected format: CLIENT_ID:CLIENT_SECRET"
    exit 1
fi

echo "Decrypting Tailscale OAuth credentials (enter passphrase)..."
TS_OAUTH=$(age -d "$KEY_DIR/tailscale_oauth.age")
TS_CLIENT_ID="${TS_OAUTH%%:*}"
TS_CLIENT_SECRET="${TS_OAUTH##*:}"

# Get an OAuth access token
TS_ACCESS_TOKEN=$(curl -s -X POST "https://api.tailscale.com/api/v2/oauth/token" \
    -d "client_id=$TS_CLIENT_ID" \
    -d "client_secret=$TS_CLIENT_SECRET" \
    -d "grant_type=client_credentials" | jq -r '.access_token')

if [[ -z "$TS_ACCESS_TOKEN" || "$TS_ACCESS_TOKEN" == "null" ]]; then
    echo "Error: Failed to obtain OAuth access token"
    exit 1
fi

# Mint a fresh ephemeral auth key via API
TS_AUTHKEY=$(curl -s -X POST "https://api.tailscale.com/api/v2/tailnet/-/keys" \
    -H "Authorization: Bearer $TS_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"capabilities":{"devices":{"create":{"reusable":false,"ephemeral":true,"preauthorized":true,"tags":["tag:cloudlab"]}}}}' | jq -r '.key')

if [[ -z "$TS_AUTHKEY" || "$TS_AUTHKEY" == "null" ]]; then
    echo "Error: Failed to create ephemeral auth key"
    exit 1
fi

# Ephemeral key ensures node is auto-removed when it goes offline
sudo tailscale up --authkey="$TS_AUTHKEY"

echo "Tailscale is connected"
tailscale status
