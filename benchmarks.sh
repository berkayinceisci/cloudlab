#!/bin/bash

# ==> Benchmarks

sudo chown -R $USER /tdata

cd /tdata

# linux kernel, perf
# Define the repository URL
REPO_URL="git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git"
LATEST_TAG=$(git ls-remote --tags --sort='v:refname' $REPO_URL | \
             grep -v 'rc' | \
             grep -v '{}' | \
             tail -n1 | \
             cut -d'/' -f3)
git clone --depth 1 --branch $LATEST_TAG $REPO_URL
cd linux
cp /boot/config-$(uname -r) .config
make olddefconfig
make -j$(nproc)
cd tools/perf
make -j$(nproc)

cd /tdata

# gapbs
git clone https://github.com/sbeamer/gapbs.git
cd gapbs
make
make bench-graphs GRAPH_DIR=/tdata/graphs RAW_GRAPH_DIR=/tdata/graphs/raw

cd ~/cloudlab

echo "Benchmarks are installed"

