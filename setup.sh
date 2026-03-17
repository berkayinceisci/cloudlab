#!/bin/bash

if [ -z "$TMUX" ]; then
	echo "Error: Must be run inside a tmux session"
	exit 1
fi

FAILED=()

run_step() {
	echo "=== Running: $1 ==="
	if "$@"; then
		echo "=== $1: OK ==="
	else
		echo "=== $1: FAILED (exit code $?) ==="
		FAILED+=("$1")
	fi
}

mkdir -p $HOME/.local
export PATH="$HOME/.local/bin:$PATH"

run_step ./ssh_keys.sh # asks for user input, sets up private/public ssh keys for cloudlab
run_step ./setup_disks.sh
export DATA_DIR=/mnt/sda4

run_step ./root_packages.sh
run_step ./nonroot_packages.sh

if mountpoint -q "$DATA_DIR" 2>/dev/null; then
	run_step ./benchmarks.sh

	run_step ./kernels.sh
	run_step ./update_grub.sh
else
	echo "=== Skipping benchmarks.sh, kernels.sh, update_grub.sh (disk setup failed) ==="
	FAILED+=(./benchmarks.sh ./kernels.sh ./update_grub.sh)
fi

run_step ./settings.sh
run_step ./crontab.sh

echo ""
echo "=============================="
if [[ ${#FAILED[@]} -eq 0 ]]; then
	echo "All steps completed successfully"
else
	echo "FAILED steps (${#FAILED[@]}):"
	for step in "${FAILED[@]}"; do
		echo "  - $step"
	done
	exit 1
fi
