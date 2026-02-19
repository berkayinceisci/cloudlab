#!/bin/bash

cd $HOME

# latest linux kernel, perf
REPO_URL="git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git"
LATEST_TAG=$(git ls-remote --tags --sort='v:refname' $REPO_URL |
    grep -v 'rc' |
    grep -v '{}' |
    tail -n1 |
    cut -d'/' -f3)
git clone --depth 1 --branch $LATEST_TAG $REPO_URL
cd linux
git apply $HOME/cloudlab/patches/perf.patch

cp /boot/config-$(uname -r) .config
sed -i 's/^CONFIG_SYSTEM_TRUSTED_KEYS=.*/CONFIG_SYSTEM_TRUSTED_KEYS=""/' .config
sed -i 's/^CONFIG_SYSTEM_REVOCATION_KEYS=.*/CONFIG_SYSTEM_REVOCATION_KEYS=""/' .config
sed -i 's/^CONFIG_NVME_CORE=m/CONFIG_NVME_CORE=y/' .config
sed -i 's/^CONFIG_BLK_DEV_NVME=m/CONFIG_BLK_DEV_NVME=y/' .config
sed -i 's/^CONFIG_SATA_AHCI=m/CONFIG_SATA_AHCI=y/' .config
sed -i 's/^CONFIG_SATA_AHCI_PLATFORM=m/CONFIG_SATA_AHCI_PLATFORM=y/' .config
make olddefconfig

make -j$(nproc)
make modules
sudo make modules_install
sudo make install

cd tools/perf
make -j$(nproc)

cd $DATA_DIR

# memtis kernel
git clone git@github.com:cosmoss-jigu/memtis.git
cd memtis
git apply --directory=linux $HOME/cloudlab/patches/memtis-vmstat.patch
cd linux

make defconfig
CONFIG_OPTIONS=(
    "CONFIG_MEMCG=y"
    "CONFIG_TRANSPARENT_HUGEPAGE=y"
    "CONFIG_HTMM=y"
    "CONFIG_PERF_EVENTS_INTEL_UNCORE=y"
    "CONFIG_INTEL_UNCORE_FREQ_CONTROL=y"
)
for CONFIG in "${CONFIG_OPTIONS[@]}"; do
    SYMBOL=$(echo "$CONFIG" | cut -d'=' -f1)
    sed -i "/^$SYMBOL/d" .config
    echo "$CONFIG" >> .config
done
make olddefconfig

make -j$(nproc)
make modules
sudo make modules_install
sudo make install
