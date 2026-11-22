#!/usr/bin/env bash

# adjust this path
source_cell_location="/student/trys/Documents/tsmc45rf/MTM_RFIC/Power_Amp/"

destination_cell_location="/home/student/wmiskowicz/PROJECT_RF_WORKSPACE/PROJECT_RF/PA"
"$(dirname "$0")/../scripts/commit.sh" "$source_cell_location" "$destination_cell_location"
