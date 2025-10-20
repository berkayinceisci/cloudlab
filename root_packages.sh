#!/bin/bash

# ==> Packages

export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

sudo add-apt-repository -y ppa:git-core/ppa
sudo apt update && sudo apt upgrade -y
sudo apt install -y -o Dpkg::Options::="--force-confnew" \
    build-essential \
    vim \
    htop \
    jq \
    numactl libnuma-dev \
    hwloc \
    msr-tools \
    cpufrequtils \
    tree \
    stow \
    gnuplot \
    clangd \
    python3-venv \
    libevent-dev ncurses-dev \
    libelf-dev libdw-dev libbfd-dev \
    libpci-dev \
    acpica-tools \
    pkg-config \
    sysstat \
    i7z \
    cmake libncurses5-dev ninja-build meson \
    automake \
    xdg-utils \
    flex bison libslang2-dev libiberty-dev libzstd-dev libcap-dev libbabeltrace-ctf-dev libunwind-dev systemtap-sdt-dev \
    linux-tools-common linux-tools-generic linux-tools-$(uname -r)

sudo apt install --reinstall linux-firmware

echo "Root packages are installed"
