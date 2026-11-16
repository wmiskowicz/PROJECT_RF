#!/usr/bin/env bash

# adjust this path
source_cell_location="/home/student/jrog/tsmc45rf/MTM_RFIC/LNA_projekt"

destination_cell_location="/home/student/wmiskowicz/PROJECT_RF_WORKSPACE/PROJECT_RF/LNA"
"$(dirname "$0")/../scripts/commit.sh" "$source_cell_location" "$destination_cell_location"
