#!/bin/bash

cd /tdata

# pcm
git clone --recurse-submodules git@github.com:MoatLab/pcm.git
cd pcm
git apply $HOME/cloudlab/patches/pcm-latency.patch
mkdir build
cd build
cmake -DCMAKE_MESSAGE_LOG_LEVEL=WARNING .. > /dev/null
cmake --build . --parallel "$(nproc)" > /dev/null

cd /tdata

# silo
git clone git@github.com:MoatLab/silo.git
cd silo
MODE=perf MASSTREE=1 make -j dbtest

cd /tdata

# qdrant qdrant-client vectordb-bench
wget https://github.com/qdrant/qdrant/releases/download/v1.15.5/qdrant_1.15.5-1_amd64.deb
sudo dpkg -i qdrant_1.15.1-1_amd64.deb
rm qdrant_1.15.1-1_amd64.deb

$HOME/.local/bin/python3.11 -m pip install --upgrade pip
$HOME/.local/bin/python3.11 -m pip install "vectordb-bench[qdrant]==1.0.15"
$HOME/.local/bin/python3.11 -m pip install "qdrant-client==1.15.1"

# gapbs
git clone https://github.com/sbeamer/gapbs.git
cd gapbs
make
make bench-graphs GRAPH_DIR=/tdata/graphs RAW_GRAPH_DIR=/tdata/graphs/raw

cd /tdata

# gapbs cmds
git clone --depth 1 git@github.com:MoatLab/Pond.git
mv Pond/gapbs gapbs-cmds
rm -rf Pond

cd $HOME/cloudlab

echo "Benchmarks are installed"

