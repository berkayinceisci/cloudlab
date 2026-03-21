#!/bin/bash

if [ -z "$TMUX" ]; then
	echo "Error: Must be run inside a tmux session"
	exit 1
fi

FAILED=()
declare -A FAIL_LOGS
LOG_DIR=$(mktemp -d)

run_step() {
	local log="$LOG_DIR/$(basename "$1").log"
	echo "=== Running: $1 ==="
	if "$@" > >(tee "$log") 2>&1; then
		echo "=== $1: OK ==="
		rm -f "$log"
	else
		echo "=== $1: FAILED (exit code $?) ==="
		FAILED+=("$1")
		FAIL_LOGS["$1"]="$log"
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
	for step in "${FAILED[@]}"; do
		if [[ -f "${FAIL_LOGS[$step]}" ]]; then
			echo ""
			echo "--- Last 30 lines of $step ---"
			tail -30 "${FAIL_LOGS[$step]}"
		fi
	done
	rm -rf "$LOG_DIR"
	exit 1
fi
