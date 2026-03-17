#!/bin/bash
set -euo pipefail

# Idempotent disk setup for CloudLab machines.
# Handles two layouts:
#   - Typical: sda=SSD (OS), sdb=HDD → sda4→/mnt/sda4, sdb→/mnt/hdd
#   - Inverted: sdb=SSD (OS), sda=HDD → sdb4→/mnt/sda4, sda1→/mnt/hdd
# Detects SSD vs HDD via rotational flag. SSD data partition always gets
# /mnt/sda4 (DATA_DIR). HDD gets /mnt/hdd. If only one disk, it gets /mnt/sda4.
# Safe to run on first setup or after OS reset (won't reformat existing ext4).

MNT_SSD="/mnt/sda4"
MNT_HDD="/mnt/hdd"

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

# Remove PVs from all potential data partitions
for dev in /dev/sda /dev/sda1 /dev/sda4 /dev/sdb /dev/sdb4; do
	if [[ -b "$dev" ]] && sudo pvs "$dev" &>/dev/null; then
		echo "Removing PV $dev..."
		sudo pvremove -f "$dev"
	fi
done

# --- Unmount stale mounts from previous runs ---

for mnt in "$MNT_SSD" "$MNT_HDD"; do
	if mountpoint -q "$mnt" 2>/dev/null; then
		echo "Unmounting stale $mnt..."
		sudo umount "$mnt"
	fi
done

# Remove stale fstab entries (will re-add correct ones later)
sudo sed -i "\|$MNT_SSD|d" /etc/fstab
sudo sed -i "\|$MNT_HDD|d" /etc/fstab

# --- Identify OS disk and find data partitions ---

ROOT_DISK=$(lsblk -nro PKNAME "$(findmnt -no SOURCE /)")
echo "OS disk: /dev/$ROOT_DISK"

# find_data_part DISK IS_OS_DISK
# Prints the data partition device path for a given disk.
# OS disk: uses partition 4 (CloudLab convention) or creates it from free space.
# Non-OS disk: uses partition 1 if it covers the disk.
find_data_part() {
	local disk=$1
	local is_os=$2

	if [[ "$is_os" == "true" ]]; then
		# OS disk: data partition is partition 4
		if [[ -b "/dev/${disk}4" ]]; then
			echo "/dev/${disk}4"
			return
		fi
		# Try to create partition 4 from free space
		if command -v sgdisk >/dev/null 2>&1; then
			sudo sgdisk -e "/dev/$disk" >&2
		fi
		local free_start free_end
		read -r free_start free_end < <(sudo parted -s "/dev/$disk" unit MB print free 2>/dev/null |
			awk '/Free Space/{
				gsub(/MB/,""); s=$1; e=$2; sz=e-s
				if(sz>max){max=sz; ms=s; me=e}
			} END{if(max>0) printf "%dMB %dMB\n", ms, me}') || true
		if [[ -n "${free_start:-}" && -n "${free_end:-}" ]]; then
			echo "Creating /dev/${disk}4 in free space: $free_start -> $free_end" >&2
			sudo parted -s "/dev/$disk" mkpart primary ext4 "$free_start" "$free_end" >&2
			sudo partprobe "/dev/$disk" >&2
			sleep 1
			if [[ -b "/dev/${disk}4" ]]; then
				echo "/dev/${disk}4"
				return
			fi
		fi
	else
		# Non-OS disk: use partition 1 if it covers the disk
		if [[ -b "/dev/${disk}1" ]]; then
			echo "/dev/${disk}1"
			return
		fi
		# Raw disk (no partitions)
		echo "/dev/$disk"
		return
	fi
}

SSD_PART=""
HDD_PART=""

for disk in sda sdb; do
	if [[ ! -b "/dev/$disk" ]]; then
		continue
	fi

	local_is_os="false"
	if [[ "$disk" == "$ROOT_DISK" ]]; then
		local_is_os="true"
	fi

	part=$(find_data_part "$disk" "$local_is_os")
	if [[ -z "$part" ]]; then
		echo "Warning: no data partition found on /dev/$disk"
		continue
	fi

	rota=$(cat "/sys/block/$disk/queue/rotational")
	if [[ "$rota" -eq 0 ]]; then
		SSD_PART="$part"
		echo "SSD data partition: $part (/dev/$disk)"
	else
		HDD_PART="$part"
		echo "HDD data partition: $part (/dev/$disk)"
	fi
done

if [[ -z "$SSD_PART" && -z "$HDD_PART" ]]; then
	echo "Error: no data partitions found"
	exit 1
fi

# --- Format if needed (preserves data after OS reset) ---

for dev in $SSD_PART $HDD_PART; do
	if ! sudo blkid -s TYPE -o value "$dev" 2>/dev/null | grep -q ext4; then
		echo "Formatting $dev as ext4..."
		sudo mkfs.ext4 -F "$dev"
	else
		echo "$dev already has ext4, skipping format"
	fi
done

# --- Mount ---
# SSD → /mnt/sda4 (primary data dir, used by DATA_DIR)
# HDD → /mnt/hdd (bulk storage)
# If only one disk exists, it gets /mnt/sda4 regardless of type.

if [[ -n "$SSD_PART" ]]; then
	sudo mkdir -p "$MNT_SSD"
	echo "Mounting $SSD_PART -> $MNT_SSD"
	sudo mount "$SSD_PART" "$MNT_SSD"
	sudo chown "$(id -u):$(id -g)" "$MNT_SSD"
elif [[ -n "$HDD_PART" ]]; then
	# No SSD available, use HDD as primary data dir
	sudo mkdir -p "$MNT_SSD"
	echo "No SSD data partition, mounting HDD $HDD_PART -> $MNT_SSD"
	sudo mount "$HDD_PART" "$MNT_SSD"
	sudo chown "$(id -u):$(id -g)" "$MNT_SSD"
	HDD_PART="" # already used as primary
fi

if [[ -n "$HDD_PART" ]]; then
	sudo mkdir -p "$MNT_HDD"
	echo "Mounting $HDD_PART -> $MNT_HDD"
	sudo mount "$HDD_PART" "$MNT_HDD"
	sudo chown "$(id -u):$(id -g)" "$MNT_HDD"
fi

# --- Update fstab ---

# Remove stale /tdata entry
if grep -q '/tdata' /etc/fstab; then
	echo "Removing stale /tdata fstab entry..."
	sudo sed -i '\|/tdata|d' /etc/fstab
fi

# Add UUID-based entries for active mounts
if mountpoint -q "$MNT_SSD" 2>/dev/null; then
	SSD_UUID=$(sudo blkid -s UUID -o value "$(findmnt -no SOURCE "$MNT_SSD")")
	echo "UUID=$SSD_UUID $MNT_SSD ext4 defaults 0 2" | sudo tee -a /etc/fstab
fi

if mountpoint -q "$MNT_HDD" 2>/dev/null; then
	HDD_UUID=$(sudo blkid -s UUID -o value "$(findmnt -no SOURCE "$MNT_HDD")")
	echo "UUID=$HDD_UUID $MNT_HDD ext4 defaults 0 2" | sudo tee -a /etc/fstab
fi

# --- Remove stale /tdata mount point ---

if [[ -d /tdata ]] && ! mountpoint -q /tdata 2>/dev/null; then
	echo "Removing stale /tdata directory..."
	sudo rm -rf /tdata
fi

echo ""
echo "Done. Mounts:"
df -h "$MNT_SSD"
if mountpoint -q "$MNT_HDD" 2>/dev/null; then
	df -h "$MNT_HDD"
fi
