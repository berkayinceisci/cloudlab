#!/bin/bash
set -euo pipefail

GRUB_FILE="/etc/default/grub"

# Set memcg kernel (6.3.0+) as default boot kernel
SUBMENU=$(grep -oP "submenu\s+'\K[^']+" /boot/grub/grub.cfg | head -1)
MENUENTRY=$(grep -oP "menuentry\s+'\K[^']*6\.3\.0\+[^']*" /boot/grub/grub.cfg | head -1)
sudo sed -i "s/^GRUB_DEFAULT=.*/GRUB_DEFAULT=\"${SUBMENU}>${MENUENTRY}\"/" "$GRUB_FILE"

# Update GRUB_CMDLINE_LINUX_DEFAULT
sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="systemd.unified_cgroup_hierarchy=yes mitigations=off"/' "$GRUB_FILE"

sudo update-grub
