#!/usr/bin/env bash

# adjust this path
source_cell_location="home/student/wmiskowicz/PROJECT_RF_WORKSPACE/PROJECT_RF/drv"

# Internal logic
destination_cell_location="/home/student/wmiskowicz/PROJECT_RF_WORKSPACE/PROJECT_RF/DRV"
cp $source_cell_location/* $destination_cell_location/ -R

cd $destination_cell_location
setfacl -R -m u:wmiskowicz:rwx 
