#!/bin/sh

# ==> Settings

sudo mkdir /dev/hugepages1G
sudo mount -t hugetlbfs -o pagesize=1G none /dev/hugepages1G

. "./config.sh" || exit
check_conf

echo "Settings are applied"
