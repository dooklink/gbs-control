#!/bin/bash

# Run individual scripts for 60Hz 640x480 setup
echo -e "\n32.4MHz pixel clock 4x interpolation:"
bash ./gbs_640x480@60Hz_4x32.4MHz.sh
echo -e "\nTurning off bob angle detection:"
bash ./gbs_byps_bob.sh
echo -e "\nTurning off all output filtering/processing:"
bash ./gbs_byps_output_proc.sh

