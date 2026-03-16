#!/bin/bash
set -euo pipefail

ENTRIES=(
	"@reboot bash $HOME/cloudlab/settings.sh"
	"@reboot bash $HOME/cloudlab/tailscale.sh"
)

for entry in "${ENTRIES[@]}"; do
	if ! crontab -l 2>/dev/null | grep -qF "$entry"; then
		(
			crontab -l 2>/dev/null || true
			echo "$entry"
		) | crontab -
	fi
done
