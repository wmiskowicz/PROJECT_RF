#!/usr/bin/env bash

# adjust this path
source_cell_location="home/student/zschab/Desktop/tsmc45rf/MTM_RFIC"

destination_cell_location="/home/student/wmiskowicz/PROJECT_RF_WORKSPACE/PROJECT_RF/LO"
"$(dirname "$0")/../scripts/commit.sh" "$source_cell_location" "$destination_cell_location"
