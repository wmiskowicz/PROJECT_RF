#!/usr/bin/env bash

# adjust this path
source_cell_location="/home/student/wmiskowicz/tsmc45rf/MTM_RFIC/LNA_CG_CAS"

# Internal logic
destination_cell_location="/home/student/wmiskowicz/PROJECT_RF_WORKSPACE/PROJECT_RF/LNA"
cp $source_cell_location/* $destination_cell_location/ -R

cd $destination_cell_location
setfacl -R -m u:wmiskowicz:rwx 
