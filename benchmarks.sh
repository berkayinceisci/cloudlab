#!/bin/bash

# ==> Benchmarks

sudo chown -R $USER /tdata

cd /tdata
git clone https://github.com/sbeamer/gapbs.git
cd gapbs
make
make bench-graphs GRAPH_DIR=/tdata/graphs RAW_GRAPH_DIR=/tdata/graphs/raw
cd ~/cloudlab

echo "Benchmarks are installed"

