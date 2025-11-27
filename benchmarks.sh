#!/bin/bash

# ==> Benchmarks

cd /tdata

# pcm
git clone --recurse-submodules git@github.com:MoatLab/pcm.git
cd pcm
git apply ~/cloudlab/patches/pcm-latency.patch
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

cd ~/cloudlab

echo "Benchmarks are installed"

