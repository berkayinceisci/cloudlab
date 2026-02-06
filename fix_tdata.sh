#!/bin/bash
set -euo pipefail

# Fix /tdata mount on CloudLab machines where the LVM setup is broken.
# Typical symptom: /tdata doesn't exist, /dev/emulab/data is missing,
# but lsblk shows a large secondary disk (usually sdb).

MOUNT_POINT="/tdata"
VG_NAME="emulab"
LV_NAME="data"

# Find the secondary disk (not sda)
DISK=""
for d in /dev/sd[b-z] /dev/nvme[0-9]n1; do
    if [[ -b "$d" ]]; then
        DISK="$d"
        break
    fi
done

if [[ -z "$DISK" ]]; then
    echo "Error: No secondary disk found"
    exit 1
fi

echo "Using disk: $DISK"

# Check if already mounted
if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
    echo "$MOUNT_POINT is already mounted, nothing to do"
    exit 0
fi

# Check if the LV already exists and just needs mounting
if [[ -e "/dev/$VG_NAME/$LV_NAME" ]]; then
    echo "LV /dev/$VG_NAME/$LV_NAME exists, mounting..."
    sudo mkdir -p "$MOUNT_POINT"
    sudo mount "/dev/$VG_NAME/$LV_NAME" "$MOUNT_POINT"
    sudo chown "$(id -u):$(id -g)" "$MOUNT_POINT"
    echo "$MOUNT_POINT mounted successfully"
    exit 0
fi

# Clean up broken VG if it exists with missing PVs
if sudo vgs "$VG_NAME" &>/dev/null; then
    echo "VG $VG_NAME exists but LV is missing, cleaning up..."
    sudo vgreduce --removemissing --force "$VG_NAME" 2>/dev/null || true

    # If VG still exists after cleanup, extend it with our disk
    if sudo vgs "$VG_NAME" &>/dev/null; then
        sudo pvcreate -ff -y "$DISK"
        sudo vgextend "$VG_NAME" "$DISK"
    else
        # VG was removed (had no PVs left), recreate
        sudo pvcreate -ff -y "$DISK"
        sudo vgcreate "$VG_NAME" "$DISK"
    fi
else
    # No VG at all, create from scratch
    sudo pvcreate -ff -y "$DISK"
    sudo vgcreate "$VG_NAME" "$DISK"
fi

# Create LV and filesystem
sudo lvcreate -l 100%FREE -n "$LV_NAME" "$VG_NAME"
sudo mkfs.ext4 -F "/dev/$VG_NAME/$LV_NAME"

# Mount
sudo mkdir -p "$MOUNT_POINT"
sudo mount "/dev/$VG_NAME/$LV_NAME" "$MOUNT_POINT"
sudo chown "$(id -u):$(id -g)" "$MOUNT_POINT"

# Add to fstab if not already there
if ! grep -q "$MOUNT_POINT" /etc/fstab; then
    echo "/dev/$VG_NAME/$LV_NAME $MOUNT_POINT ext4 defaults 0 2" | sudo tee -a /etc/fstab
fi

echo "$MOUNT_POINT mounted successfully ($(df -h "$MOUNT_POINT" | awk 'NR==2{print $2}'))"
