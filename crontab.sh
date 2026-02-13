#!/bin/bash

ENTRIES=(
    "@reboot sh $HOME/cloudlab/settings.sh"
    "@reboot bash $HOME/cloudlab/tailscale.sh"
)

for entry in "${ENTRIES[@]}"; do
    if ! crontab -l 2>/dev/null | grep -qF "$entry"; then
        (crontab -l 2>/dev/null; echo "$entry") | crontab -
    fi
done
