#!/bin/bash

GRUB_FILE="/etc/default/grub"

# Update GRUB_CMDLINE_LINUX_DEFAULT
sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="systemd.unified_cgroup_hierarchy=yes"/' "$GRUB_FILE"

sudo update-grub
