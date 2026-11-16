#!/usr/bin/env bash
# Usage: commit.sh <source_cell_location> <destination_cell_location>
set -e
src="$1"; dst="$2"

cp -R "$src"/* "$dst"/
setfacl -R -m u:wmiskowicz:rwx "$dst"
