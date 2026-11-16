#!/usr/bin/env bash

# adjust this path
source_cell_location="/home/student/jstraczek/tsmc45rf/MTM_RFIC/VCO"

destination_cell_location="/home/student/wmiskowicz/PROJECT_RF_WORKSPACE/PROJECT_RF/DRV"
"$(dirname "$0")/../scripts/commit.sh" "$source_cell_location" "$destination_cell_location"
