#!/bin/bash
set -euo pipefail

# Idempotent disk setup: tear down LVM, mount /dev/sda4 and /dev/sdb as ext4.
# Safe to run on first setup or after OS reset (won't reformat existing ext4).

SDA4="/dev/sda4"
SDB="/dev/sdb"
MNT_SSD="/mnt/sda4"
MNT_HDD="/mnt/hdd"

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

for dev in "$SDA4" "$SDB"; do
    if sudo pvs "$dev" &>/dev/null; then
        echo "Removing PV $dev..."
        sudo pvremove -f "$dev"
    fi
done

# --- Format if needed (preserves data after OS reset) ---

for dev in "$SDA4" "$SDB"; do
    if ! sudo blkid -s TYPE -o value "$dev" 2>/dev/null | grep -q ext4; then
        echo "Formatting $dev as ext4..."
        sudo mkfs.ext4 -F "$dev"
    else
        echo "$dev already has ext4, skipping format"
    fi
done

# --- Mount ---

sudo mkdir -p "$MNT_SSD" "$MNT_HDD"

if ! mountpoint -q "$MNT_SSD" 2>/dev/null; then
    echo "Mounting $SDA4 -> $MNT_SSD"
    sudo mount "$SDA4" "$MNT_SSD"
fi

if ! mountpoint -q "$MNT_HDD" 2>/dev/null; then
    echo "Mounting $SDB -> $MNT_HDD"
    sudo mount "$SDB" "$MNT_HDD"
fi

# --- Set ownership ---

sudo chown "$(id -u):$(id -g)" "$MNT_SSD"
sudo chown "$(id -u):$(id -g)" "$MNT_HDD"

# --- Update fstab ---

# Remove stale /tdata entry
if grep -q '/tdata' /etc/fstab; then
    echo "Removing stale /tdata fstab entry..."
    sudo sed -i '\|/tdata|d' /etc/fstab
fi

# Add UUID-based entries for both mounts
SDA4_UUID=$(sudo blkid -s UUID -o value "$SDA4")
SDB_UUID=$(sudo blkid -s UUID -o value "$SDB")

if ! grep -q "$MNT_SSD" /etc/fstab; then
    echo "UUID=$SDA4_UUID $MNT_SSD ext4 defaults 0 2" | sudo tee -a /etc/fstab
fi

if ! grep -q "$MNT_HDD" /etc/fstab; then
    echo "UUID=$SDB_UUID $MNT_HDD ext4 defaults 0 2" | sudo tee -a /etc/fstab
fi

# --- Remove stale /tdata mount point ---

if [[ -d /tdata ]] && ! mountpoint -q /tdata 2>/dev/null; then
    echo "Removing stale /tdata directory..."
    sudo rm -rf /tdata
fi

echo "Done. Mounts:"
df -h "$MNT_SSD" "$MNT_HDD"
