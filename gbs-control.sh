#!/bin/bash
# GBS82000 & GBS8220 Control over I2C bash script
# 
# Code structure & Interactive shell script from raspi-config
#

INTERACTIVE=True

#
calc_wt_size() {
  # NOTE: it's tempting to redirect stderr to /dev/null, so supress error 
  # output from tput. However in this case, tput detects neither stdout or 
  # stderr is a tty and so only gives default 80, 24 values
  WT_HEIGHT=17
  WT_WIDTH=$(tput cols)

  if [ -z "$WT_WIDTH" ] || [ "$WT_WIDTH" -lt 60 ]; then
    WT_WIDTH=80
  fi
  if [ "$WT_WIDTH" -gt 178 ]; then
    WT_WIDTH=120
  fi
  WT_MENU_HEIGHT=$(($WT_HEIGHT-8))
}

#
#
do_prog_rgb_ntsc_640x480() {
	sudo cp -f settings/defaults/NTSC-640x480@60Hz.set settings/defaults/current.set >> log.txt 2>&1
}

do_prog_rgb_ntsc_800x600() {
	sudo cp -f settings/defaults/NTSC-800x600@60Hz.set settings/defaults/current.set >> log.txt 2>&1
}

folder_scripts () {
  cd scripts
}

do_script() {
  # Set the prompt for the select command
  PS3="Type a number or 'q' to quit: "
   
  # Create a list of files to display
  folder_scripts
  fileList=$(find ./ -maxdepth 1 -type f)
  cd ..
   
  # Show a menu and ask for input. If the user entered a valid choice,
  # then invoke the editor on that file
  select fileName in $fileList; do
  if [ -n "$fileName" ]; then
    sudo "scripts/"$fileName >> log.txt 2>&1
  fi
  break
  done
}

#
#
do_set_Vds_hb_st() {
  sudo i2cset -r -y 1 0x17 0xf0 0x03 b
  CURRENT_VALUE=$(( (($(sudo i2cget -y 1 0x17 0x05) & 0x0f) << 8) + $(sudo i2cget -y 1 0x17 0x04) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Hblank Start (0 - 4095)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sudo i2cset -r -y 1 0x17 0xf0 0x03 b
	sudo i2cset -r -y -m 0x0f 1 0x17 0x05 $((NEW_VALUE >> 8))
	sudo i2cset -r -y -m 0xff 1 0x17 0x04 $((NEW_VALUE & 0xFF))
  fi
}

do_set_Vds_hb_sp() {
  sudo i2cset -r -y 1 0x17 0xf0 0x03 b
  CURRENT_VALUE=$(( ($(sudo i2cget -y 1 0x17 0x06) << 4) + ($(sudo i2cget -y 1 0x17 0x05) >> 4) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Hblank Stop (0 - 4095)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sudo i2cset -r -y 1 0x17 0xf0 0x03 b
	sudo i2cset -r -y -m 0xff 1 0x17 0x06 $((NEW_VALUE >> 4))
	sudo i2cset -r -y -m 0xf0 1 0x17 0x05 $(( (NEW_VALUE & 0x00F) << 4))
  fi
}

do_set_Vds_vb_st() {
  sudo i2cset -r -y 1 0x17 0xf0 0x03 b
  CURRENT_VALUE=$(( (($(sudo i2cget -y 1 0x17 0x08) & 0x07) << 8) + $(sudo i2cget -y 1 0x17 0x07) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Vblank Start (0 - 2047)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sudo i2cset -r -y 1 0x17 0xf0 0x03 b
	sudo i2cset -r -y -m 0x07 1 0x17 0x08 $((NEW_VALUE >> 8))
	sudo i2cset -r -y -m 0xff 1 0x17 0x07 $((NEW_VALUE & 0xFF))
  fi
}

do_set_Vds_vb_sp() {
  sudo i2cset -r -y 1 0x17 0xf0 0x03 b
  CURRENT_VALUE=$(( (($(sudo i2cget -y 1 0x17 0x09) & 0x7f) << 4) + ($(sudo i2cget -y 1 0x17 0x08) >> 4) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Vblank Stop (0 - 2047)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sudo i2cset -r -y 1 0x17 0xf0 0x03 b
	sudo i2cset -r -y -m 0x7f 1 0x17 0x09 $((NEW_VALUE >> 4))
	sudo i2cset -r -y -m 0xf0 1 0x17 0x08 $(( (NEW_VALUE & 0x00F) << 4))
  fi
}

do_set_Vds_hs_st() {
  sudo i2cset -r -y 1 0x17 0xf0 0x03 b
  CURRENT_VALUE=$(( (($(sudo i2cget -y 1 0x17 0x0b) & 0x0f) << 8) + $(sudo i2cget -y 1 0x17 0x0a) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Hsync Start (0 - 4095)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sudo i2cset -r -y 1 0x17 0xf0 0x03 b
	sudo i2cset -r -y -m 0x0f 1 0x17 0x0b $((NEW_VALUE >> 8))
	sudo i2cset -r -y -m 0xff 1 0x17 0x0a $((NEW_VALUE & 0xFF))
  fi
}

do_set_Vds_hs_sp() {
  sudo i2cset -r -y 1 0x17 0xf0 0x03 b
  CURRENT_VALUE=$(( ($(sudo i2cget -y 1 0x17 0x0c) << 4) + ($(sudo i2cget -y 1 0x17 0x0b) >> 4) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Hsync Stop (0 - 4095)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sudo i2cset -r -y 1 0x17 0xf0 0x03 b
	sudo i2cset -r -y -m 0xff 1 0x17 0x0c $((NEW_VALUE >> 4))
	sudo i2cset -r -y -m 0xf0 1 0x17 0x0b $(( (NEW_VALUE & 0x00F) << 4))
  fi
}

do_set_Vds_vs_st() {
  sudo i2cset -r -y 1 0x17 0xf0 0x03 b
  CURRENT_VALUE=$(( (($(sudo i2cget -y 1 0x17 0x0e) & 0x07) << 8) + $(sudo i2cget -y 1 0x17 0x0d) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Vsync Start (0 - 2047)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sudo i2cset -r -y 1 0x17 0xf0 0x03 b
	sudo i2cset -r -y -m 0x07 1 0x17 0x0e $((NEW_VALUE >> 8))
	sudo i2cset -r -y -m 0xff 1 0x17 0x0d $((NEW_VALUE & 0xFF))
  fi
}

do_set_Vds_vs_sp() {
  sudo i2cset -r -y 1 0x17 0xf0 0x03 b
  CURRENT_VALUE=$(( (($(sudo i2cget -y 1 0x17 0x0f) & 0x7f) << 4) + ($(sudo i2cget -y 1 0x17 0x0e) >> 4) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Vsync Stop (0 - 2047)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sudo i2cset -r -y 1 0x17 0xf0 0x03 b
	sudo i2cset -r -y -m 0x7f 1 0x17 0x0f $((NEW_VALUE >> 4))
	sudo i2cset -r -y -m 0xf0 1 0x17 0x0e $(( (NEW_VALUE & 0x00F) << 4))
  fi
}

do_set_Vds_dis_hb_st() {
  sudo i2cset -r -y 1 0x17 0xf0 0x03 b
  CURRENT_VALUE=$(( (($(sudo i2cget -y 1 0x17 0x11) & 0x0f) << 8) + $(sudo i2cget -y 1 0x17 0x10) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Hblank Start (0 - 4095)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sudo i2cset -r -y 1 0x17 0xf0 0x03 b
	sudo i2cset -r -y -m 0x0f 1 0x17 0x11 $((NEW_VALUE >> 8))
	sudo i2cset -r -y -m 0xff 1 0x17 0x10 $((NEW_VALUE & 0xFF))
  fi
}

do_set_Vds_dis_hb_sp() {
  sudo i2cset -r -y 1 0x17 0xf0 0x03 b
  CURRENT_VALUE=$(( ($(sudo i2cget -y 1 0x17 0x12) << 4) + ($(sudo i2cget -y 1 0x17 0x11) >> 4) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Hblank Stop (0 - 4095)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sudo i2cset -r -y 1 0x17 0xf0 0x03 b
	sudo i2cset -r -y -m 0xff 1 0x17 0x12 $((NEW_VALUE >> 4))
	sudo i2cset -r -y -m 0xf0 1 0x17 0x11 $(( (NEW_VALUE & 0x00F) << 4))
  fi
}

do_set_Vds_dis_vb_st() {
  sudo i2cset -r -y 1 0x17 0xf0 0x03 b
  CURRENT_VALUE=$(( (($(sudo i2cget -y 1 0x17 0x14) & 0x07) << 8) + $(sudo i2cget -y 1 0x17 0x13) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Vblank Start (0 - 2047)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sudo i2cset -r -y 1 0x17 0xf0 0x03 b
	sudo i2cset -r -y -m 0x07 1 0x17 0x14 $((NEW_VALUE >> 8))
	sudo i2cset -r -y -m 0xff 1 0x17 0x13 $((NEW_VALUE & 0xFF))
  fi
}

do_set_Vds_dis_vb_sp() {
  sudo i2cset -r -y 1 0x17 0xf0 0x03 b
  CURRENT_VALUE=$(( (($(sudo i2cget -y 1 0x17 0x15) & 0x7f) << 4) + ($(sudo i2cget -y 1 0x17 0x14) >> 4) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Vblank Stop (0 - 2047)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sudo i2cset -r -y 1 0x17 0xf0 0x03 b
	sudo i2cset -r -y -m 0x7f 1 0x17 0x15 $((NEW_VALUE >> 4))
	sudo i2cset -r -y -m 0xf0 1 0x17 0x14 $(( (NEW_VALUE & 0x00F) << 4))
  fi
}

do_set_Vds_ext_hb_st() {
  sudo i2cset -r -y 1 0x17 0xf0 0x03 b
  CURRENT_VALUE=$(( (($(sudo i2cget -y 1 0x17 0x6e) & 0x0f) << 8) + $(sudo i2cget -y 1 0x17 0x6d) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Hblank Start (0 - 4095)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sudo i2cset -r -y 1 0x17 0xf0 0x03 b
	sudo i2cset -r -y -m 0x0f 1 0x17 0x6e $((NEW_VALUE >> 8))
	sudo i2cset -r -y -m 0xff 1 0x17 0x6d $((NEW_VALUE & 0xFF))
  fi
}

do_set_Vds_ext_hb_sp() {
  sudo i2cset -r -y 1 0x17 0xf0 0x03 b
  CURRENT_VALUE=$(( ($(sudo i2cget -y 1 0x17 0x6f) << 4) + ($(sudo i2cget -y 1 0x17 0x6e) >> 4) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Hblank Stop (0 - 4095)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sudo i2cset -r -y 1 0x17 0xf0 0x03 b
	sudo i2cset -r -y -m 0xff 1 0x17 0x6f $((NEW_VALUE >> 4))
	sudo i2cset -r -y -m 0xf0 1 0x17 0x6e $(( (NEW_VALUE & 0x00F) << 4))
  fi
}

do_set_Vds_ext_vb_st() {
  sudo i2cset -r -y 1 0x17 0xf0 0x03 b
  CURRENT_VALUE=$(( (($(sudo i2cget -y 1 0x17 0x71) & 0x07) << 8) + $(sudo i2cget -y 1 0x17 0x70) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Vblank Start (0 - 2047)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sudo i2cset -r -y 1 0x17 0xf0 0x03 b
	sudo i2cset -r -y -m 0x07 1 0x17 0x71 $((NEW_VALUE >> 8))
	sudo i2cset -r -y -m 0xff 1 0x17 0x70 $((NEW_VALUE & 0xFF))
  fi
}

do_set_Vds_ext_vb_sp() {
  sudo i2cset -r -y 1 0x17 0xf0 0x03 b
  CURRENT_VALUE=$(( (($(sudo i2cget -y 1 0x17 0x72) & 0x7f) << 4) + ($(sudo i2cget -y 1 0x17 0x71) >> 4) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Vblank Stop (0 - 2047)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sudo i2cset -r -y 1 0x17 0xf0 0x03 b
	sudo i2cset -r -y -m 0x7f 1 0x17 0x72 $((NEW_VALUE >> 4))
	sudo i2cset -r -y -m 0xf0 1 0x17 0x71 $(( (NEW_VALUE & 0x00F) << 4))
  fi
}

do_output_geometry_menu() {
while true; do
  FUN=$(whiptail --title "Rasberry Pi GB8200 / GBS8220 Controller" --menu "Output Geometry" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
    "4.1 Set Vds_hb_st" "Set Horizontal Left Offset" \
	"4.2 Set Vds_hb_sp" "Set Horizontal Width" \
	"4.3 Set Vds_vb_st" "Set Vertical Top Offset" \
	"4.4 Set Vds_vb_sp" "Set Vertical Length" \
    "4.5 Set Vds_hs_st" "Set Horizontal sync start position" \
	"4.6 Set Vds_hs_sp" "Set Horizontal sync stop position " \
	"4.7 Set Vds_vs_st" "Set Vertical sync start position" \
	"4.8 Set Vds_vs_sp" "Set Vertical sync stop position" \
	"4.9 Set Vds_dis_hb_st" "Set Horizontal blanking start position" \
	"4.10 Set Vds_dis_hb_sp" "Set Horizontal blanking stop position" \
	"4.11 Set Vds_dis_vb_st" "Set Vertical blanking start position" \
	"4.12 Set Vds_dis_vb_sp" "Set Vertical blanking stop position" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      4.1\ *) do_set_Vds_hb_st ;;
	  4.2\ *) do_set_Vds_hb_sp ;;
	  4.3\ *) do_set_Vds_vb_st ;;
	  4.4\ *) do_set_Vds_vb_sp ;;
	  4.5\ *) do_set_Vds_hs_st ;;
	  4.6\ *) do_set_Vds_hs_sp ;;
	  4.7\ *) do_set_Vds_vs_st ;;
	  4.8\ *) do_set_Vds_vs_sp ;;
	  4.9\ *) do_set_Vds_dis_hb_st ;;
	  4.10\ *) do_set_Vds_dis_hb_sp ;;
	  4.11\ *) do_set_Vds_dis_vb_st ;;
	  4.12\ *) do_set_Vds_dis_vb_sp ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
done
}

#
#
do_set_Sp_pre_coast() {
  sudo i2cset -r -y 1 0x17 0xf0 0x05 b
  CURRENT_VALUE=$(( $(sudo i2cget -y 1 0x17 0x38) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Coast Start (0 - 255)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sudo i2cset -r -y 1 0x17 0xf0 0x05 b
	sudo i2cset -r -y -m 0xff 1 0x17 0x38 $NEW_VALUE
  fi
}

do_set_Sp_post_coast() {
  sudo i2cset -r -y 1 0x17 0xf0 0x05 b
  CURRENT_VALUE=$(( $(sudo i2cget -y 1 0x17 0x39) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Coast Stop (0 - 255)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sudo i2cset -r -y 1 0x17 0xf0 0x05 b
	sudo i2cset -r -y -m 0xff 1 0x17 0x39 $NEW_VALUE
  fi
}

do_input_capture_menu() {
while true; do
  FUN=$(whiptail --title "Rasberry Pi GB8200 / GBS8220 Controller" --menu "Input Sync Capture" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
	"5.1 Set Sp_pre_coast" "Set the coast start point before vertical sync line number" \
	"5.2 Set Sp_post_coast" "Set when coast will disable (return to normal PLL function)" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      5.1\ *) do_set_Sp_pre_coast ;;
	  5.2\ *) do_set_Sp_post_coast ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
done
}

#
#
do_set_Vds_vscale() {
  sudo i2cset -r -y 1 0x17 0xf0 0x03 b
  CURRENT_VALUE=$(( (($(sudo i2cget -y 1 0x17 0x18) & 0x7f) << 4) + ($(sudo i2cget -y 1 0x17 0x17) >> 4) ))
  NEW_VALUE=$(whiptail --inputbox "Enter V Scalling (0 - 1023)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sudo i2cset -r -y 1 0x17 0xf0 0x03 b
	sudo i2cset -r -y -m 0x7f 1 0x17 0x18 $((NEW_VALUE >> 4))
	sudo i2cset -r -y -m 0xf0 1 0x17 0x17 $(( (NEW_VALUE & 0x00F) << 4))
  fi
}

do_set_Vds_hscale() {
  sudo i2cset -r -y 1 0x17 0xf0 0x03 b
  CURRENT_VALUE=$(( (($(sudo i2cget -y 1 0x17 0x17) & 0x03) << 8) + $(sudo i2cget -y 1 0x17 0x16) ))
  NEW_VALUE=$(whiptail --inputbox "Enter H Scalling (0 - 1023)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sudo i2cset -r -y 1 0x17 0xf0 0x03 b
	sudo i2cset -r -y -m 0x03 1 0x17 0x17 $((NEW_VALUE >> 8))
	sudo i2cset -r -y -m 0xff 1 0x17 0x16 $((NEW_VALUE & 0xff))
  fi
}

do_hv_scalling_menu() {
while true; do
  FUN=$(whiptail --title "Rasberry Pi GB8200 / GBS8220 Controller" --menu "H/V Scalling" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
	"6.1 Set Vds_hscale" "Set horizontal scalling" \
	"6.2 Set Vds_vscale" "Set vertical scalling" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      6.1\ *) do_set_Vds_hscale ;;
	  6.2\ *) do_set_Vds_vscale ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
done
}


do_save() {

  NEW_VALUE=$(whiptail --inputbox "Enter Setting Name" 20 60 "default" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sudo cp -f settings/defaults/current.set "settings/"$NEW_VALUE".set" >> log.txt 2>&1
  fi
}

folder_settings () {
  cd settings
}

do_load() {
  # Set the prompt for the select command
  PS3="Type a number or 'q' to quit: "
   
  # Create a list of files to display
  folder_settings
  fileList=$(find ./ -maxdepth 1 -type f)
  cd ..
   
  # Show a menu and ask for input. If the user entered a valid choice,
  # then invoke the editor on that file
  select fileName in $fileList; do
  if [ -n "$fileName" ]; then
    sudo cp -f settings/$fileName settings/defaults/current.set >> log.txt 2>&1
  fi
  break
done
}



do_finish() {
  exit 0
}

# Everything needs to be run as root
if [ $(id -u) -ne 0 ]; then
  printf "Script must be run as root. Try 'sudo ./gbs-config'\n"
  exit 1
fi

#
# Interactive use loop
#
#sudo python scripts/rawProg.py scripts/start.txt > log.txt 2>&1
calc_wt_size
while true; do
  FUN=$(whiptail --title "Rasberry Pi GB8200 / GBS8220 Controller" --menu "Setup Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
	"1 Set RGB NTSC 640x480" "For RGB 50/60Hz input" \
	"2 Set RGB NTSC 800x600" "For RGB 50/60Hz input" \
	"3 Run Scripts" "These may have pre-requisites" \
	"4 Geometry" "Shift output image and blanking" \
	"5 Coast" "Input sync & sampling settings" \
	"6 H/V Scalling" "Change output canvas scalling" \
	"7 Save Settings" "Save current settings to file" \
	"8 Load Settings" "Load previous settings from file"\
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    do_finish
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      1\ *) do_prog_rgb_ntsc_640x480 ;;
	  2\ *) do_prog_rgb_ntsc_800x600 ;;
	  3\ *) do_script ;;
	  4\ *) do_output_geometry_menu ;;
	  5\ *) do_input_capture_menu ;;
	  6\ *) do_hv_scalling_menu ;;
	  7\ *) do_save ;;
	  8\ *) do_load ;;
      *) whiptail --msgbox "Programmer error: unrecognised option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  else
    exit 1
  fi
done
