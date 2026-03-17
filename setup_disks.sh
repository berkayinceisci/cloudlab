#!/bin/bash
set -euo pipefail

# Idempotent disk setup: tear down LVM, mount data partition from /dev/sda as ext4.
# Handles two CloudLab layouts:
#   - sda has sda4 (or free space to create it): use sda4, optionally sdb as HDD
#   - sda1 covers entire disk (sdb is OS disk): use sda1 after LVM teardown
# Safe to run on first setup or after OS reset (won't reformat existing ext4).

MNT_DATA="/mnt/sda4"
MNT_HDD="/mnt/hdd"

# --- Determine if /dev/sdb is usable as a secondary data disk ---
# Only use sdb if it exists and is NOT the OS disk

HAS_SDB=false
if [[ -b /dev/sdb ]]; then
	ROOT_DISK=$(lsblk -nro PKNAME "$(findmnt -no SOURCE /)" 2>/dev/null || true)
	if [[ "$ROOT_DISK" != "sdb" ]]; then
		HAS_SDB=true
	fi
fi

# --- Tear down LVM if present (must happen before partition changes) ---

if mountpoint -q /tdata 2>/dev/null; then
	echo "Unmounting /tdata..."
	sudo umount /tdata
fi

if sudo lvs emulab/node0-bs &>/dev/null; then
	echo "Removing LV emulab/node0-bs..."
	sudo lvchange -an emulab/node0-bs
	sudo lvremove -f emulab/node0-bs
fi

if sudo vgs emulab &>/dev/null; then
	echo "Removing VG emulab..."
	sudo vgremove -f emulab
fi

# Remove PVs from sda partitions and sdb (if usable)
for dev in /dev/sda1 /dev/sda4; do
	if [[ -b "$dev" ]] && sudo pvs "$dev" &>/dev/null; then
		echo "Removing PV $dev..."
		sudo pvremove -f "$dev"
	fi
done
if [[ "$HAS_SDB" == "true" ]] && sudo pvs /dev/sdb &>/dev/null; then
	echo "Removing PV /dev/sdb..."
	sudo pvremove -f /dev/sdb
fi

# --- Determine data partition on /dev/sda ---

DATA_DEV=""

if [[ -b /dev/sda4 ]]; then
	# sda4 already exists
	DATA_DEV="/dev/sda4"
else
	# Try to create sda4 from free space
	if command -v sgdisk >/dev/null 2>&1; then
		sudo sgdisk -e /dev/sda
	fi
	read -r FREE_START FREE_END < <(sudo parted -s /dev/sda unit MB print free 2>/dev/null \
		| awk '/Free Space/{
			gsub(/MB/,""); s=$1; e=$2; sz=e-s
			if(sz>max){max=sz; ms=s; me=e}
		} END{if(max>0) printf "%dMB %dMB\n", ms, me}') || true
	if [[ -n "${FREE_START:-}" && -n "${FREE_END:-}" ]]; then
		echo "Creating /dev/sda4 in free space: $FREE_START -> $FREE_END"
		sudo parted -s /dev/sda mkpart primary ext4 "$FREE_START" "$FREE_END"
		sudo partprobe /dev/sda
		sleep 1
		if [[ ! -b /dev/sda4 ]]; then
			echo "Error: /dev/sda4 still not found after partitioning"
			exit 1
		fi
		DATA_DEV="/dev/sda4"
	elif [[ -b /dev/sda1 ]]; then
		# sda1 covers entire disk (LVM already torn down), use it directly
		echo "/dev/sda4 not available, using /dev/sda1 as data partition"
		DATA_DEV="/dev/sda1"
	else
		echo "Error: no usable partition found on /dev/sda"
		exit 1
	fi
fi

echo "Data partition: $DATA_DEV"

# --- Format if needed (preserves data after OS reset) ---

DEVS=("$DATA_DEV")
if [[ "$HAS_SDB" == "true" ]]; then
	DEVS+=("/dev/sdb")
fi

for dev in "${DEVS[@]}"; do
	if ! sudo blkid -s TYPE -o value "$dev" 2>/dev/null | grep -q ext4; then
		echo "Formatting $dev as ext4..."
		sudo mkfs.ext4 -F "$dev"
	else
		echo "$dev already has ext4, skipping format"
	fi
done

# --- Mount ---

sudo mkdir -p "$MNT_DATA"
if [[ "$HAS_SDB" == "true" ]]; then
	sudo mkdir -p "$MNT_HDD"
fi

if ! mountpoint -q "$MNT_DATA" 2>/dev/null; then
	echo "Mounting $DATA_DEV -> $MNT_DATA"
	sudo mount "$DATA_DEV" "$MNT_DATA"
fi

if [[ "$HAS_SDB" == "true" ]]; then
	if ! mountpoint -q "$MNT_HDD" 2>/dev/null; then
		echo "Mounting /dev/sdb -> $MNT_HDD"
		sudo mount /dev/sdb "$MNT_HDD"
	fi
fi

# --- Set ownership ---

sudo chown "$(id -u):$(id -g)" "$MNT_DATA"
if [[ "$HAS_SDB" == "true" ]]; then
	sudo chown "$(id -u):$(id -g)" "$MNT_HDD"
fi

# --- Update fstab ---

# Remove stale /tdata entry
if grep -q '/tdata' /etc/fstab; then
	echo "Removing stale /tdata fstab entry..."
	sudo sed -i '\|/tdata|d' /etc/fstab
fi

# Add UUID-based entries for mounts
DATA_UUID=$(sudo blkid -s UUID -o value "$DATA_DEV")

if ! grep -q "$MNT_DATA" /etc/fstab; then
	echo "UUID=$DATA_UUID $MNT_DATA ext4 defaults 0 2" | sudo tee -a /etc/fstab
fi

if [[ "$HAS_SDB" == "true" ]]; then
	SDB_UUID=$(sudo blkid -s UUID -o value /dev/sdb)
	if ! grep -q "$MNT_HDD" /etc/fstab; then
		echo "UUID=$SDB_UUID $MNT_HDD ext4 defaults 0 2" | sudo tee -a /etc/fstab
	fi
fi

# --- Remove stale /tdata mount point ---

if [[ -d /tdata ]] && ! mountpoint -q /tdata 2>/dev/null; then
	echo "Removing stale /tdata directory..."
	sudo rm -rf /tdata
fi

echo "Done. Mounts:"
df -h "$MNT_DATA"
if [[ "$HAS_SDB" == "true" ]]; then
	df -h "$MNT_HDD"
fi
