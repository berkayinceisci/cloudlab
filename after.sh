# commands that ask for user input, run this script after installation is complete and the environment is reloaded

./tailscale.sh
# Add popos host key to known_hosts (wait for MagicDNS)
for i in $(seq 1 10); do
    keys=$(ssh-keyscan popos 2>/dev/null)
    if [[ -n "$keys" ]]; then
        echo "$keys" >> "$HOME/.ssh/known_hosts"
        echo "Added popos host key to known_hosts"
        break
    fi
    echo "Waiting for MagicDNS to resolve popos... (attempt $i/10)"
    sleep 2
done

./dotfiles.sh

echo "Logging into Atuin (shell history sync)..."
atuin login && atuin sync
