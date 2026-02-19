#!/bin/bash
set -euo pipefail

# Lightweight recovery script for after OS reset.
# setup_disks.sh is idempotent, so just call it.

cd "$(dirname "$0")"
./setup_disks.sh
