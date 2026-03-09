#!/bin/bash
set -euo pipefail

# Idempotent disk setup: tear down LVM, mount /dev/sda4 and /dev/sdb as ext4.
# Safe to run on first setup or after OS reset (won't reformat existing ext4).
# Skips /dev/sdb if it doesn't exist.

SDA4="/dev/sda4"
SDB="/dev/sdb"
MNT_SDA4="/mnt/sda4"
MNT_HDD="/mnt/hdd"

HAS_SDB=false
if [[ -b "$SDB" ]]; then
	HAS_SDB=true
fi

# --- Create /dev/sda4 if it doesn't exist (some Cloudlab instances lack it) ---

if [[ ! -b "$SDA4" ]]; then
	echo "$SDA4 not found, creating partition from free space..."
	# Fix GPT to use all available space if needed
	if command -v sgdisk >/dev/null 2>&1; then
		sudo sgdisk -e /dev/sda
	fi
	# Find the largest free space region (start and end)
	read -r FREE_START FREE_END < <(sudo parted -s /dev/sda unit MB print free 2>/dev/null \
		| awk '/Free Space/{
			gsub(/MB/,""); s=$1; e=$2; sz=e-s
			if(sz>max){max=sz; ms=s; me=e}
		} END{if(max>0) printf "%dMB %dMB\n", ms, me}')
	if [[ -z "$FREE_START" || -z "$FREE_END" ]]; then
		echo "Error: no usable free space found on /dev/sda"
		exit 1
	fi
	echo "Creating partition in free space: $FREE_START -> $FREE_END"
	sudo parted -s /dev/sda mkpart primary ext4 "$FREE_START" "$FREE_END"
	# Wait for kernel to pick up the new partition
	sudo partprobe /dev/sda
	sleep 1
	if [[ ! -b "$SDA4" ]]; then
		echo "Error: $SDA4 still not found after partitioning"
		exit 1
	fi
	echo "Created $SDA4"
fi

# --- Tear down LVM if present ---

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

DEVS=("$SDA4")
if [[ "$HAS_SDB" == "true" ]]; then
	DEVS+=("$SDB")
fi

for dev in "${DEVS[@]}"; do
	if sudo pvs "$dev" &>/dev/null; then
		echo "Removing PV $dev..."
		sudo pvremove -f "$dev"
	fi
done

# --- Format if needed (preserves data after OS reset) ---

for dev in "${DEVS[@]}"; do
	if ! sudo blkid -s TYPE -o value "$dev" 2>/dev/null | grep -q ext4; then
		echo "Formatting $dev as ext4..."
		sudo mkfs.ext4 -F "$dev"
	else
		echo "$dev already has ext4, skipping format"
	fi
done

# --- Mount ---

sudo mkdir -p "$MNT_SDA4"
if [[ "$HAS_SDB" == "true" ]]; then
	sudo mkdir -p "$MNT_HDD"
fi

if ! mountpoint -q "$MNT_SDA4" 2>/dev/null; then
	echo "Mounting $SDA4 -> $MNT_SDA4"
	sudo mount "$SDA4" "$MNT_SDA4"
fi

if [[ "$HAS_SDB" == "true" ]]; then
	if ! mountpoint -q "$MNT_HDD" 2>/dev/null; then
		echo "Mounting $SDB -> $MNT_HDD"
		sudo mount "$SDB" "$MNT_HDD"
	fi
fi

# --- Set ownership ---

sudo chown "$(id -u):$(id -g)" "$MNT_SDA4"
if [[ "$HAS_SDB" == "true" ]]; then
	sudo chown "$(id -u):$(id -g)" "$MNT_HDD"
fi

# --- Update fstab ---

# Remove stale /tdata entry
if grep -q '/tdata' /etc/fstab; then
	echo "Removing stale /tdata fstab entry..."
	sudo sed -i '\|/tdata|d' /etc/fstab
fi

# Add UUID-based entries for both mounts
SDA4_UUID=$(sudo blkid -s UUID -o value "$SDA4")

if ! grep -q "$MNT_SDA4" /etc/fstab; then
	echo "UUID=$SDA4_UUID $MNT_SDA4 ext4 defaults 0 2" | sudo tee -a /etc/fstab
fi

if [[ "$HAS_SDB" == "true" ]]; then
	SDB_UUID=$(sudo blkid -s UUID -o value "$SDB")
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
df -h "$MNT_SDA4"
if [[ "$HAS_SDB" == "true" ]]; then
	df -h "$MNT_HDD"
fi
