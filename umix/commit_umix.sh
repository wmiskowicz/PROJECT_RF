#!/usr/bin/env bash

# adjust this path
source_cell_location="/home/student/lperczynski/PROJECT_RF/umix"

destination_cell_location="/home/student/wmiskowicz/PROJECT_RF_WORKSPACE/PROJECT_RF/UMIX"
"$(dirname "$0")/../scripts/commit.sh" "$source_cell_location" "$destination_cell_location"
