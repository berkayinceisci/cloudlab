#!/bin/bash
set -euo pipefail

sudo mkdir -p /dev/hugepages1G
if ! mountpoint -q /dev/hugepages1G; then
	sudo mount -t hugetlbfs -o pagesize=1G none /dev/hugepages1G
fi

sudo modprobe msr
sudo chmod g+rw /dev/cpu/*/msr
sudo modprobe intel_uncore_frequency

sudo sysctl -w kernel.perf_cpu_time_max_percent=0

. "$HOME/cloudlab/config.sh" || exit
check_conf

echo "Settings are applied"
