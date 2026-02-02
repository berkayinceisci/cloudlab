#!/bin/bash
set -euo pipefail

ENTRIES=(
    "@reboot sh $HOME/cloudlab/settings.sh"
)

for entry in "${ENTRIES[@]}"; do
    if ! crontab -l 2>/dev/null | grep -qF "$entry"; then
        (crontab -l 2>/dev/null; echo "$entry") | crontab -
    fi
done
