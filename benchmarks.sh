#!/bin/bash
set -euo pipefail

if [[ ! -d "$DATA_DIR/colo-scripts" ]]; then
	git clone git@github.com:MoatLab/colo-scripts "$DATA_DIR/colo-scripts"
fi
$DATA_DIR/colo-scripts/install.sh
