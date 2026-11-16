#!/usr/bin/env bash

# adjust this path
source_cell_location="/home/student/wmiskowicz/tsmc45rf/MTM_RFIC/power_amp"

destination_cell_location="/home/student/wmiskowicz/PROJECT_RF_WORKSPACE/PROJECT_RF/PA"
"$(dirname "$0")/../scripts/commit.sh" "$source_cell_location" "$destination_cell_location"
