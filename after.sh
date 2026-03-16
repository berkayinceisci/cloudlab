#!/bin/bash
set -euo pipefail

# commands that ask for user input, run this script after installation is complete and the environment is reloaded

./tailscale.sh

# Add popos host key to known_hosts (wait for MagicDNS)
if ssh-keygen -F popos >/dev/null 2>&1; then
	echo "popos host key already in known_hosts, skipping..."
else
	for i in $(seq 1 10); do
		if keys=$(ssh-keyscan popos 2>/dev/null) && [[ -n "$keys" ]]; then
			echo "$keys" >>"$HOME/.ssh/known_hosts"
			echo "Added popos host key to known_hosts"
			break
		fi
		echo "Waiting for MagicDNS to resolve popos... (attempt $i/10)"
		sleep 2
	done
fi

./dotfiles.sh

# Atuin: login only if no active session
if [[ -s "$HOME/.local/share/atuin/session" ]]; then
	echo "Atuin already logged in, skipping..."
else
	echo "Logging into Atuin (shell history sync)..."
	until atuin login; do
		echo "Login failed, retrying..."
	done
fi
atuin sync
