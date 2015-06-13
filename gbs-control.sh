#!/bin/bash
# GBS82000 & GBS8220 Control over I2C bash script
# Version 0.3
# Code structure & Interactive shell script from raspi-config
#

INTERACTIVE=True

#
calc_wt_size() {
  # NOTE: it's tempting to redirect stderr to /dev/null, so suppress error 
  # output from tput. However in this case, tput detects neither stdout or 
  # stderr is a tty and so only gives default 80, 24 values
  WT_HEIGHT=$(tput lines)
  WT_WIDTH=$(tput cols)

  if [ "$WT_WIDTH" -gt 30 ]; then
    WT_HIGHT=$(($(tput lines) - 10))
  fi

  if [ -z "$WT_WIDTH" ] || [ "$WT_WIDTH" -lt 60 ]; then
    WT_WIDTH=80
  fi
  if [ "$WT_WIDTH" -gt 180 ]; then
    WT_WIDTH=160
  fi
  if [ "$WT_WIDTH" -ne 74 ]; then
    WT_WIDTH=$(($(tput cols) - 10))
  fi

  WT_MENU_HEIGHT=$(($WT_HEIGHT-8))
}

detect_revision() {
  REVISION=$(cat /proc/cpuinfo | grep revision)
  LEN=${#REVISION}
  POS=$((LEN -1))
  REV=${REVISION:POS}
  if [ "$REV" = "0" ] || [ "$REV" = "1" ]; then
    I2C_PORT=$((0))
  else
    I2C_PORT=$((1))
  fi
}

folder_scripts () {
  cd scripts
}

#
#
do_help() {
whiptail --title "Raspberry Pi GB8200 Controller v0.3" --scrolltext --msgbox \
"System has two modes, 1.Menu and 2.Video Processing
Use the following hot-keys to navigate.

Navigation:
F1 - Switch to Pi Menu
F2 - Switch to Currently loaded settings
F5 - Quick save settings (While in Video Mode)
F7 - Quick load settings (While in Video Mode)

Grave/Tilde(\`/~)+1 - Switch menu to RGBHV 480p (VGA)
Grave/Tilde(\`/~)+2 - Switch menu to YPbPr 480p
Grave/Tilde(\`/~)+3 - Switch menu to RGBHV 576p (Non-standard)
Grave/Tilde(\`/~)+4 - Switch menu to YPbPr 576p

Fine adjustments - Use while in Video Mode:
CTRL+1 - Increase vertical scale (if enabled)
CTRL+2 - Decrease vertical scale (if enabled)
CTRL+3 - Decrease horizontal scale
CTRL+4 - Increase horizontal scale
CTRL+5 - Move image up
CTRL+6 - Move image down
CTRL+7 - Move image left
CTRL+8 - Move image right" \
  $WT_HEIGHT $WT_WIDTH 3>&1 1>&2 2>&3
}

#
#
do_deinterlace_enable() {
  CURRENT_VALUE=$(sed -n 1p settings/defaults/current.dei)
  if [ "$CURRENT_VALUE" == "false" ]; then
    DEFAULT_NO="--defaultno"
  else
    DEFAULT_NO=""
  fi
  whiptail $DEFAULT_NO --yes-button "Enable" --no-button "Disable" --yesno "Dynamic De-interlace Enable/Disable" 10 50 3>&1 1>&2 2>&3
  RET=$?
  if [ $RET -eq 1 ]; then
    # NO / Disable Branch
    sed -i 1c\\false settings/defaults/current.dei
  elif [ $RET -eq 0 ]; then
    # YES / Enable Branch
    sed -i 1c\\true settings/defaults/current.dei
  fi
}

do_deinterlace_offset() {
  CURRENT_VALUE=$(sed -n 2p settings/defaults/current.dei)
  NEW_VALUE=$(whiptail --inputbox "Enter Vertical Offset (+ve or -ve)" 20 60 -- "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sed -i 2c\\$NEW_VALUE settings/defaults/current.dei
  fi
}

do_deinterlace_detection() {
  sudo python /home/pi/scripts/regProg.py /home/pi/settings/defaults/current.set
  sudo i2cset -y $I2C_PORT 0x17 0xf0 0x00
  VLINES=$(( (($(sudo i2cget -y $I2C_PORT 0x17 0x08) & 0x0F ) << 7) + ($(sudo i2cget -y $I2C_PORT 0x17 0x07) >> 1) ))
  sudo python /home/pi/scripts/regProg.py /home/pi/settings/defaults/pi.set
  CURRENT_VALUE=$(sed -n 3p settings/defaults/current.dei)
  if [ "$CURRENT_VALUE" == "interlaced" ]; then
    DEFAULT_NO="--defaultno"
  else
    DEFAULT_NO=""
  fi
  whiptail $DEFAULT_NO --yes-button "Progressive" --no-button "Interlaced" \
  --yesno "Mode Detection:

Total Vertical Video Lines Detected = "$VLINES"
Is the current source Interlaced or Progressive?" \
  20 60 3>&1 1>&2 2>&3
  RET=$?
  if [ $RET -eq 1 ]; then
    # NO / Interlaced Branch
    sed -i 3c\\interlaced settings/defaults/current.dei
    sed -i 4c\\$VLINES settings/defaults/current.dei
  elif [ $RET -eq 0 ]; then
    # YES / Progressive Branch
    sed -i 3c\\progressive settings/defaults/current.dei
    sed -i 4c\\$VLINES settings/defaults/current.dei
  fi
}

do_deinterlace_default() {
  CURRENT_VALUE=$(sed -n 5p settings/defaults/current.dei)
  if [ "$CURRENT_VALUE" == "interlaced" ]; then
    DEFAULT_NO="--defaultno"
  else
    DEFAULT_NO=""
  fi
  whiptail $DEFAULT_NO --yes-button "Progressive" --no-button "Interlaced" \
  --yesno "Default Mode:

Select the normal operating mode
Is the geometry set-up for Interlaced or Progressive?" \
  20 60 3>&1 1>&2 2>&3
  RET=$?
  if [ $RET -eq 1 ]; then
    # NO / Interlaced Branch
    sed -i 5c\\interlaced settings/defaults/current.dei
  elif [ $RET -eq 0 ]; then
    # YES / Progressive Branch
    sed -i 5c\\progressive settings/defaults/current.dei
  fi
}

do_deinterlace_help() {
  whiptail --title "Raspberry Pi GB8200 Controller v0.3" --scrolltext --msgbox \
  "The de-interlace switcher attempts to detect the mode from the TIVA chip. \
Use the detect menu to get the current number of lines reported. \
You will need to enter if this represents interlaced or progressive video.

Vertical offset can be entered to adjust for the Vsync difference between modes.
The default mode can be changed to reflect if the settings file is normally \
set-up for interlace or progressive scan signals. This sets the basis for the \
vertical offset.

This information is saved in a separate file for each of the video \
settings and will be remembered. (It is not a global setting.)
If a video settings file has no corresponding de-interlace settings file then \
the last active settings will be used." \
  $WT_HEIGHT $WT_WIDTH 3>&1 1>&2 2>&3
}

do_deinterlace_menu() {
  while true; do
    DEI_ENABLED=$(sed -n 1p settings/defaults/current.dei)
    if [ "$DEI_ENABLED" == "false" ]; then
      DEI_ENABLED="Disabled"
    else
      DEI_ENABLED="Enabled"
    fi
  DEI_OFFSET=$(sed -n 2p settings/defaults/current.dei)
	DEI_DETECT=$(sed -n 4p settings/defaults/current.dei)" = "$(sed -n 3p settings/defaults/current.dei)
  DEI_DEFAULT=$(sed -n 5p settings/defaults/current.dei)
    FUN=$(whiptail --title "Raspberry Pi GB8200 Controller v0.3" \
	--menu "Dynamic De-interlace Settings" \
	$WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT \
	--cancel-button Back --ok-button Select -- \
    "2.1 Enable/Disable: " "$DEI_ENABLED" \
  	"2.2 Vertical Offset: " "$DEI_OFFSET" \
    "2.3 Set Detection: " "$DEI_DETECT"\
    "2.4 Set Default: " "$DEI_DEFAULT"\
  	"2.5 HELP" "Display Help Guide" \
    3>&1 1>&2 2>&3)
    RET=$?
    if [ $RET -eq 1 ]; then
      return 0
    elif [ $RET -eq 0 ]; then
      case "$FUN" in
        2.1\ *) do_deinterlace_enable ;;
  	    2.2\ *) do_deinterlace_offset ;;
        2.3\ *) do_deinterlace_detection ;;
        2.4\ *) do_deinterlace_default ;;
  	    2.5\ *) do_deinterlace_help ;; 
        *) whiptail --msgbox "Programmer error: unrecognised option" 20 60 1 ;;
      esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
    fi
  done
}

#
#
do_set_Vds_hb_st() {
  LOW=$(sed -n 773p settings/defaults/current.set)
  HIGH=$(sed -n 774p settings/defaults/current.set)
  CURRENT_VALUE=$(( (( $HIGH & 0x0f) << 8) + $LOW ))
  NEW_VALUE=$(whiptail --inputbox "Enter Hblank Start (0 - 4095)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    HIGH=$(( ((NEW_VALUE >> 8) & 0x0f) + ($HIGH & 0xf0) ))
	  LOW=$((NEW_VALUE & 0xff))
    sed -i 773c\\$LOW settings/defaults/current.set
	  sed -i 774c\\$HIGH settings/defaults/current.set
  fi
}

do_set_Vds_hb_sp() {
  LOW=$(sed -n '774p' settings/defaults/current.set)
  HIGH=$(sed -n '775p' settings/defaults/current.set)
  CURRENT_VALUE=$(( ($HIGH << 4) + ($LOW >> 4) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Hblank Stop (0 - 4095)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    HIGH=$(( NEW_VALUE >> 4 ))
	  LOW=$(( ((NEW_VALUE << 4) & 0xf0) + ($LOW & 0x0f) ))
    sed -i 774c\\$LOW settings/defaults/current.set
	  sed -i 775c\\$HIGH settings/defaults/current.set
  fi
}

do_set_Vds_vb_st() {
  LOW=$(sed -n 776p settings/defaults/current.set)
  HIGH=$(sed -n 777p settings/defaults/current.set)
  CURRENT_VALUE=$(( (( $HIGH & 0x07) << 8) + $LOW ))
  NEW_VALUE=$(whiptail --inputbox "Enter Vblank Start (0 - 2047)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    HIGH=$(( ((NEW_VALUE >> 8) & 0x07) + ($HIGH & 0xf8) ))
	  LOW=$((NEW_VALUE & 0xff))
    sed -i 776c\\$LOW settings/defaults/current.set
	  sed -i 777c\\$HIGH settings/defaults/current.set
  fi
}

do_set_Vds_vb_sp() {
  LOW=$(sed -n '777p' settings/defaults/current.set)
  HIGH=$(sed -n '778p' settings/defaults/current.set)
  CURRENT_VALUE=$(( (($HIGH & 0x7f) << 4) + ($LOW >> 4) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Vblank Stop (0 - 2047)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    HIGH=$(( ((NEW_VALUE >> 4) & 0x7f) + ($HIGH & 0x80) ))
	  LOW=$(( ((NEW_VALUE << 4) & 0xf0) + ($LOW & 0x0f) ))
    sed -i 777c\\$LOW settings/defaults/current.set
	  sed -i 778c\\$HIGH settings/defaults/current.set
  fi
}

do_set_Vds_hs_st() {
  LOW=$(sed -n 779p settings/defaults/current.set)
  HIGH=$(sed -n 780p settings/defaults/current.set)
  CURRENT_VALUE=$(( (( $HIGH & 0x0f) << 8) + $LOW ))
  NEW_VALUE=$(whiptail --inputbox "Enter Hsync Start (0 - 4095)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    HIGH=$(( ((NEW_VALUE >> 8) & 0x0f) + ($HIGH & 0xf0) ))
	  LOW=$((NEW_VALUE & 0xff))
    sed -i 779c\\$LOW settings/defaults/current.set
	  sed -i 780c\\$HIGH settings/defaults/current.set
  fi
}

do_set_Vds_hs_sp() {
  LOW=$(sed -n '780p' settings/defaults/current.set)
  HIGH=$(sed -n '781p' settings/defaults/current.set)
  CURRENT_VALUE=$(( ($HIGH << 4) + ($LOW >> 4) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Hsync Stop (0 - 4095)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    HIGH=$(( NEW_VALUE >> 4 ))
	  LOW=$(( ((NEW_VALUE << 4) & 0xf0) + ($LOW & 0x0f) ))
    sed -i 780c\\$LOW settings/defaults/current.set
	  sed -i 781c\\$HIGH settings/defaults/current.set
  fi
}

do_set_Vds_vs_st() {
  LOW=$(sed -n 782p settings/defaults/current.set)
  HIGH=$(sed -n 783p settings/defaults/current.set)
  CURRENT_VALUE=$(( (( $HIGH & 0x07) << 8) + $LOW ))
  NEW_VALUE=$(whiptail --inputbox "Enter Vsync Start (0 - 2047)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    HIGH=$(( ((NEW_VALUE >> 8) & 0x07) + ($HIGH & 0xf8) ))
	  LOW=$((NEW_VALUE & 0xff))
    sed -i 782c\\$LOW settings/defaults/current.set
	  sed -i 783c\\$HIGH settings/defaults/current.set
  fi
}

do_set_Vds_vs_sp() {
  LOW=$(sed -n '783p' settings/defaults/current.set)
  HIGH=$(sed -n '784p' settings/defaults/current.set)
  CURRENT_VALUE=$(( (($HIGH & 0x7f) << 4) + ($LOW >> 4) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Vsync Stop (0 - 2047)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    HIGH=$(( ((NEW_VALUE >> 4) & 0x7f) + ($HIGH & 0x80) ))
	  LOW=$(( ((NEW_VALUE << 4) & 0xf0) + ($LOW & 0x0f) ))
    sed -i 783c\\$LOW settings/defaults/current.set
	  sed -i 784c\\$HIGH settings/defaults/current.set
  fi
}

do_set_Vds_dis_hb_st() {
  LOW=$(sed -n 785p settings/defaults/current.set)
  HIGH=$(sed -n 786p settings/defaults/current.set)
  CURRENT_VALUE=$(( (( $HIGH & 0x0f) << 8) + $LOW ))
  NEW_VALUE=$(whiptail --inputbox "Enter Hblank Start (0 - 4095)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    HIGH=$(( ((NEW_VALUE >> 8) & 0x0f) + ($HIGH & 0xf0) ))
	  LOW=$((NEW_VALUE & 0xff))
    sed -i 785c\\$LOW settings/defaults/current.set
	  sed -i 786c\\$HIGH settings/defaults/current.set
  fi
}

do_set_Vds_dis_hb_sp() {
  LOW=$(sed -n '786p' settings/defaults/current.set)
  HIGH=$(sed -n '787p' settings/defaults/current.set)
  CURRENT_VALUE=$(( ($HIGH << 4) + ($LOW >> 4) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Hblank Stop (0 - 4095)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    HIGH=$(( NEW_VALUE >> 4 ))
	  LOW=$(( ((NEW_VALUE << 4) & 0xf0) + ($LOW & 0x0f) ))
    sed -i 786c\\$LOW settings/defaults/current.set
	  sed -i 787c\\$HIGH settings/defaults/current.set
  fi
}

do_set_Vds_dis_vb_st() {
  LOW=$(sed -n 788p settings/defaults/current.set)
  HIGH=$(sed -n 789p settings/defaults/current.set)
  CURRENT_VALUE=$(( (( $HIGH & 0x07) << 8) + $LOW ))
  NEW_VALUE=$(whiptail --inputbox "Enter Vblank Start (0 - 2047)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    HIGH=$(( ((NEW_VALUE >> 8) & 0x07) + ($HIGH & 0xf8) ))
	  LOW=$((NEW_VALUE & 0xff))
    sed -i 788c\\$LOW settings/defaults/current.set
	  sed -i 789c\\$HIGH settings/defaults/current.set
  fi
}

do_set_Vds_dis_vb_sp() {
  LOW=$(sed -n '789p' settings/defaults/current.set)
  HIGH=$(sed -n '790p' settings/defaults/current.set)
  CURRENT_VALUE=$(( (($HIGH & 0x7f) << 4) + ($LOW >> 4) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Vblank Stop (0 - 2047)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    HIGH=$(( ((NEW_VALUE >> 4) & 0x7f) + ($HIGH & 0x80) ))
	  LOW=$(( ((NEW_VALUE << 4) & 0xf0) + ($LOW & 0x0f) ))
    sed -i 789c\\$LOW settings/defaults/current.set
	  sed -i 790c\\$HIGH settings/defaults/current.set
  fi
}

do_output_geometry_menu() {
  while true; do
    FUN=$(whiptail --title "Raspberry Pi GB8200 Controller v0.3" --menu "Output Geometry" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
    "3.1 Set Vds_hb_st" "Set Horizontal Left Offset" \
    "3.2 Set Vds_hb_sp" "Set Horizontal Width" \
  	"3.3 Set Vds_vb_st" "Set Vertical Top Offset" \
  	"3.4 Set Vds_vb_sp" "Set Vertical Length" \
    "3.5 Set Vds_hs_st" "Set Horizontal sync start position" \
  	"3.6 Set Vds_hs_sp" "Set Horizontal sync stop position " \
    "3.7 Set Vds_vs_st" "Set Vertical sync start position" \
    "3.8 Set Vds_vs_sp" "Set Vertical sync stop position" \
    "3.9 Set Vds_dis_hb_st" "Set Horizontal blanking start position" \
    "3.10 Set Vds_dis_hb_sp" "Set Horizontal blanking stop position" \
    "3.11 Set Vds_dis_vb_st" "Set Vertical blanking start position" \
    "3.12 Set Vds_dis_vb_sp" "Set Vertical blanking stop position" \
    3>&1 1>&2 2>&3)
    RET=$?
    if [ $RET -eq 1 ]; then
      return 0
    elif [ $RET -eq 0 ]; then
      case "$FUN" in
        3.1\ *) do_set_Vds_hb_st ;;
  	    3.2\ *) do_set_Vds_hb_sp ;;
  	    3.3\ *) do_set_Vds_vb_st ;;
  	    3.4\ *) do_set_Vds_vb_sp ;;
  	    3.5\ *) do_set_Vds_hs_st ;;
  	    3.6\ *) do_set_Vds_hs_sp ;;
  	    3.7\ *) do_set_Vds_vs_st ;;
  	    3.8\ *) do_set_Vds_vs_sp ;;
  	    3.9\ *) do_set_Vds_dis_hb_st ;;
  	    3.10\ *) do_set_Vds_dis_hb_sp ;;
  	    3.11\ *) do_set_Vds_dis_vb_st ;;
  	    3.12\ *) do_set_Vds_dis_vb_sp ;;
        *) whiptail --msgbox "Programmer error: unrecognised option" 20 60 1 ;;
      esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
    fi
  done
}

#
#
do_set_Sp_pre_coast() {
  CURRENT_VALUE=$(( $(sed -n '1337p' settings/defaults/current.set) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Coast Start (0 - 255)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sed -i 1337c\\$NEW_VALUE settings/defaults/current.set
  fi
}

do_set_Sp_post_coast() {
  CURRENT_VALUE=$(( $(sed -n '1338p' settings/defaults/current.set) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Coast Stop (0 - 255)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sed -i 1338c\\$NEW_VALUE settings/defaults/current.set
  fi
}

do_input_capture_menu() {
while true; do
  FUN=$(whiptail --title "Raspberry Pi GB8200 Controller v0.3" --menu "Input Sync Capture" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
	"4.1 Set Sp_pre_coast" "Set Vsync coast pre-length" \
	"4.2 Set Sp_post_coast" "Set Vsync coast post-length" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      4.1\ *) do_set_Sp_pre_coast ;;
	    4.2\ *) do_set_Sp_post_coast ;;
      *) whiptail --msgbox "Programmer error: unrecognised option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
done
}

#
#
do_set_Vds_vscale() {
  LOW=$(sed -n '792p' settings/defaults/current.set)
  HIGH=$(sed -n '793p' settings/defaults/current.set)
  CURRENT_VALUE=$(( (($HIGH & 0x7f) << 4) + ($LOW >> 4) ))
  NEW_VALUE=$(whiptail --inputbox "Enter V Scaling (0 - 1023)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    HIGH=$(( ((NEW_VALUE >> 4) & 0x7f) + ($HIGH & 0x80) ))
	  LOW=$(( ((NEW_VALUE << 4) & 0xf0) + ($LOW & 0x0f) ))
    sed -i 792c\\$LOW settings/defaults/current.set
	  sed -i 793c\\$HIGH settings/defaults/current.set
  fi
}

do_set_Vds_hscale() {
  LOW=$(sed -n 791p settings/defaults/current.set)
  HIGH=$(sed -n 792p settings/defaults/current.set)
  CURRENT_VALUE=$(( (( $HIGH & 0x03) << 8) + $LOW ))
  NEW_VALUE=$(whiptail --inputbox "Enter H Scaling (0 - 1023)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    HIGH=$(( ((NEW_VALUE >> 8) & 0x03) + ($HIGH & 0xfc) ))
	  LOW=$((NEW_VALUE & 0xff))
    sed -i 791c\\$LOW settings/defaults/current.set
	  sed -i 792c\\$HIGH settings/defaults/current.set
  fi
}

do_hv_scalling_menu() {
  while true; do
    FUN=$(whiptail --title "Raspberry Pi GB8200 Controller v0.3" --menu "H/V Scaling" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
  	"5.1 Set Vds_hscale" "Set horizontal scaling" \
  	"5.2 Set Vds_vscale" "Set vertical scaling" \
    3>&1 1>&2 2>&3)
    RET=$?
    if [ $RET -eq 1 ]; then
      return 0
    elif [ $RET -eq 0 ]; then
      case "$FUN" in
        5.1\ *) do_set_Vds_hscale ;;
  	    5.2\ *) do_set_Vds_vscale ;;
        *) whiptail --msgbox "Programmer error: unrecognised option" 20 60 1 ;;
      esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
    fi
  done
}

#
#
do_sync_level() {
  LOW=$(sed -n 830p settings/defaults/current.set)
  HIGH=$(sed -n 831p settings/defaults/current.set)
  CURRENT_VALUE=$(( (( $HIGH & 0x01) << 8) + $LOW ))
  NEW_VALUE=$(whiptail --inputbox "Enter Sync Level (0 - 511)" 20 60 "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    HIGH=$(( ((NEW_VALUE >> 8) & 0x01) + ($HIGH & 0xfe) ))
	  LOW=$((NEW_VALUE & 0xff))
    sed -i 830c\\$LOW settings/defaults/current.set
	  sed -i 831c\\$HIGH settings/defaults/current.set
  fi
}

#
#
do_colour_enable() {
  CURRENT_VALUE=$(( $(sed -n 831p settings/defaults/current.set) ))
  if [ "$(( (($CURRENT_VALUE >> 4) & 0x01) ))" -eq "1" ]; then
    DEFAULT_NO="--defaultno"
  else
    DEFAULT_NO=""
  fi
  whiptail $DEFAULT_NO --yes-button "Enable" --no-button "Disable" --yesno "Colour Processing Enable/Disable" 10 50 3>&1 1>&2 2>&3
  RET=$?
  ON=$(( $CURRENT_VALUE & 0xEF ))
  OFF=$(( $CURRENT_VALUE | 0x10 ))
  if [ $RET -eq 1 ]; then
    # NO / Disable Branch
    sed -i 831c\\$OFF settings/defaults/current.set
  elif [ $RET -eq 0 ]; then
    # YES / Enable Branch
    sed -i 831c\\$ON settings/defaults/current.set
  fi
}

do_colour_brightness() {
  CURRENT_VALUE=$(( $(sed -n 827p settings/defaults/current.set) ))
  if [ "$CURRENT_VALUE" -ge 128 ]; then
    CURRENT_VALUE=$(( $CURRENT_VALUE - 256 ))
  fi
  NEW_VALUE=$(whiptail --inputbox "Enter Y' Offset (-128 to 127)" 20 60 -- "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    if [ "$NEW_VALUE" -lt "0" ]; then
      NEW_VALUE=$(($NEW_VALUE + 256 ))
      sed -i 827c\\$NEW_VALUE settings/defaults/current.set
    else
      sed -i 827c\\$NEW_VALUE settings/defaults/current.set
    fi
  fi
}

do_colour_contrast() {
  CURRENT_VALUE=$(( $(sed -n 822p settings/defaults/current.set) ))
  NEW_VALUE=$(whiptail --inputbox "Enter Y' Gain (0 to 255)" 20 60 -- "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sed -i 822c\\$NEW_VALUE settings/defaults/current.set
  fi
}

do_colour_u_gain() {
  UCOS_VALUE=$(( $(sed -n 823p settings/defaults/current.set) ))
  if [ "$UCOS_VALUE" -ge 128 ]; then
    UCOS_VALUE=$(( $UCOS_VALUE - 256 ))
  fi
  USIN_VALUE=$(( $(sed -n 825p settings/defaults/current.set) ))
  if [ "$USIN_VALUE" -ge 128 ]; then
    USIN_VALUE=$(( $USIN_VALUE - 256 ))
  fi
  folder_scripts
  HUE=$(( $(python calculateHue.py $UCOS_VALUE $USIN_VALUE) ))
  CURRENT_VALUE=$(( $(python calculateGain.py $UCOS_VALUE $USIN_VALUE) ))
  cd ..
  NEW_VALUE=$(whiptail --inputbox "Enter Pb gain (-128 to 127)" 20 60 -- "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    folder_scripts
    UCOS_VALUE=$(( $(python calculateCos.py $NEW_VALUE $HUE) ))
    USIN_VALUE=$(( $(python calculateSin.py $NEW_VALUE $HUE) ))
    cd ..
    if [ "$UCOS_VALUE" -lt "0" ]; then
      UCOS_VALUE=$(($UCOS_VALUE + 256 ))
      sed -i 823c\\$UCOS_VALUE settings/defaults/current.set
    else
      sed -i 823c\\$UCOS_VALUE settings/defaults/current.set
    fi
    if [ "$USIN_VALUE" -lt "0" ]; then
      USIN_VALUE=$(($USIN_VALUE + 256 ))
      sed -i 825c\\$USIN_VALUE settings/defaults/current.set
    else
      sed -i 825c\\$USIN_VALUE settings/defaults/current.set
    fi
  fi
}

do_colour_v_gain() {
  VCOS_VALUE=$(( $(sed -n 824p settings/defaults/current.set) ))
  if [ "$VCOS_VALUE" -ge 128 ]; then
    VCOS_VALUE=$(( $VCOS_VALUE - 256 ))
  fi
  VSIN_VALUE=$(( $(sed -n 826p settings/defaults/current.set) ))
  if [ "$VSIN_VALUE" -ge 128 ]; then
    VSIN_VALUE=$(( $VSIN_VALUE - 256 ))
  fi
  folder_scripts
  HUE=$(( $(python calculateHue.py $VCOS_VALUE $((-1* $VSIN_VALUE)) ) ))
  CURRENT_VALUE=$(( $(python calculateGain.py $VCOS_VALUE $((-1* $VSIN_VALUE))) ))
  cd ..
  NEW_VALUE=$(whiptail --inputbox "Enter Pr gain (-128 to 127)" 20 60 -- "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    folder_scripts
    VCOS_VALUE=$(( $(python calculateCos.py $NEW_VALUE $HUE) ))
    VSIN_VALUE=$(( -1* $(python calculateSin.py $NEW_VALUE $HUE) ))
    cd ..
    if [ "$VCOS_VALUE" -lt "0" ]; then
      VCOS_VALUE=$(($VCOS_VALUE + 256 ))
      sed -i 824c\\$VCOS_VALUE settings/defaults/current.set
    else
      sed -i 824c\\$VCOS_VALUE settings/defaults/current.set
    fi
    if [ "$VSIN_VALUE" -lt "0" ]; then
      VSIN_VALUE=$(($VSIN_VALUE + 256 ))
      sed -i 826c\\$VSIN_VALUE settings/defaults/current.set
    else
      sed -i 826c\\$VSIN_VALUE settings/defaults/current.set
    fi
  fi
}

do_colour_hue() {
  UCOS_VALUE=$(( $(sed -n 823p settings/defaults/current.set) ))
  if [ "$UCOS_VALUE" -ge 128 ]; then
    UCOS_VALUE=$(( $UCOS_VALUE - 256 ))
  fi
  USIN_VALUE=$(( $(sed -n 825p settings/defaults/current.set) ))
  if [ "$USIN_VALUE" -ge 128 ]; then
    USIN_VALUE=$(( $USIN_VALUE - 256 ))
  fi
  VCOS_VALUE=$(( $(sed -n 824p settings/defaults/current.set) ))
  if [ "$VCOS_VALUE" -ge 128 ]; then
    VCOS_VALUE=$(( $VCOS_VALUE - 256 ))
  fi
  VSIN_VALUE=$(( $(sed -n 826p settings/defaults/current.set) ))
  if [ "$VSIN_VALUE" -ge 128 ]; then
    VSIN_VALUE=$(( $VSIN_VALUE - 256 ))
  fi
  folder_scripts
  CURRENT_VALUE=$(( $(python calculateHue.py $UCOS_VALUE $USIN_VALUE) ))
  UGAIN=$(( $(python calculateGain.py $UCOS_VALUE $USIN_VALUE) ))
  VGAIN=$(( $(python calculateGain.py $VCOS_VALUE $VSIN_VALUE) ))
  cd ..
  NEW_VALUE=$(whiptail --inputbox "Enter Hue angle (-90 to 90)" 20 60 -- "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    folder_scripts
    UCOS_VALUE=$(( $(python calculateCos.py $UGAIN $NEW_VALUE) ))
    USIN_VALUE=$(( $(python calculateSin.py $UGAIN $NEW_VALUE) ))
    VCOS_VALUE=$(( $(python calculateCos.py $VGAIN $NEW_VALUE) ))
    VSIN_VALUE=$(( -1* $(python calculateSin.py $VGAIN $NEW_VALUE) ))
    cd ..
    if [ "$UCOS_VALUE" -lt "0" ]; then
      UCOS_VALUE=$(($UCOS_VALUE + 256 ))
      sed -i 823c\\$UCOS_VALUE settings/defaults/current.set
    else
      sed -i 823c\\$UCOS_VALUE settings/defaults/current.set
    fi
    if [ "$USIN_VALUE" -lt "0" ]; then
      USIN_VALUE=$(($USIN_VALUE + 256 ))
      sed -i 825c\\$USIN_VALUE settings/defaults/current.set
    else
      sed -i 825c\\$USIN_VALUE settings/defaults/current.set
    fi
    if [ "$VCOS_VALUE" -lt "0" ]; then
      VCOS_VALUE=$(($VCOS_VALUE + 256 ))
      sed -i 824c\\$VCOS_VALUE settings/defaults/current.set
    else
      sed -i 824c\\$VCOS_VALUE settings/defaults/current.set
    fi
    if [ "$VSIN_VALUE" -lt "0" ]; then
      VSIN_VALUE=$(($VSIN_VALUE + 256 ))
      sed -i 826c\\$VSIN_VALUE settings/defaults/current.set
    else
      sed -i 826c\\$VSIN_VALUE settings/defaults/current.set
    fi
  fi
}

do_colour_menu() {
  while true; do
    FUN=$(whiptail --title "Raspberry Pi GB8200 Controller v0.3" --menu "Colour Menu" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
  	"7.1 Enable/Disable" "Turn on/off colour expansion" \
  	"7.2 Y' Offset" "Change picture brightness" \
    "7.3 Y' Gain" "Change picture contrast" \
    "7.4 Pb/U Gain" "Change blue-luma gain" \
    "7.5 Pr/V Gain" "Change red-luma gain" \
    "7.6 Hue/Tint" "Change colour hue/tint" \
    "7.7 Advanced Menu" "Change raw colour components" \
    3>&1 1>&2 2>&3)
    RET=$?
    if [ $RET -eq 1 ]; then
      return 0
    elif [ $RET -eq 0 ]; then
      case "$FUN" in
        7.1\ *) do_colour_enable ;;
  	    7.2\ *) do_colour_brightness ;;
        7.3\ *) do_colour_contrast ;;
        7.4\ *) do_colour_u_gain ;;
        7.5\ *) do_colour_v_gain ;;
        7.6\ *) do_colour_hue ;;
        7.7\ *) do_colour_advanced_menu ;;
        *) whiptail --msgbox "Programmer error: unrecognised option" 20 60 1 ;;
      esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
    fi
  done
}

#
#
do_colour_u_cos_gain() {
  CURRENT_VALUE=$(( $(sed -n 823p settings/defaults/current.set) ))
  if [ "$CURRENT_VALUE" -ge 128 ]; then
    CURRENT_VALUE=$(( $UCOS_VALUE - 256 ))
  fi
  NEW_VALUE=$(whiptail --inputbox "Enter Pb Cos gain (-128 to 127)" 20 60 -- "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    if [ "$NEW_VALUE" -lt "0" ]; then
      NEW_VALUE=$(($NEW_VALUE + 256 ))
      sed -i 823c\\$NEW_VALUE settings/defaults/current.set
    else
      sed -i 823c\\$NEW_VALUE settings/defaults/current.set
    fi
  fi
}

do_colour_v_cos_gain() {
  CURRENT_VALUE=$(( $(sed -n 824p settings/defaults/current.set) ))
  if [ "$CURRENT_VALUE" -ge 128 ]; then
    CURRENT_VALUE=$(( $CURRENT_VALUE - 256 ))
  fi
  NEW_VALUE=$(whiptail --inputbox "Enter Pr Cos gain (-128 to 127)" 20 60 -- "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    if [ "$NEW_VALUE" -lt "0" ]; then
      NEW_VALUE=$(($NEW_VALUE + 256 ))
      sed -i 824c\\$NEW_VALUE settings/defaults/current.set
    else
      sed -i 824c\\$NEW_VALUE settings/defaults/current.set
    fi
  fi
}

do_colour_u_sin_gain() {
  CURRENT_VALUE=$(( $(sed -n 825p settings/defaults/current.set) ))
  if [ "$CURRENT_VALUE" -ge 128 ]; then
    CURRENT_VALUE=$(( $CURRENT_VALUE - 256 ))
  fi
  NEW_VALUE=$(whiptail --inputbox "Enter Pb Sin gain (-128 to 127)" 20 60 -- "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    if [ "$NEW_VALUE" -lt "0" ]; then
      NEW_VALUE=$(($NEW_VALUE + 256 ))
      sed -i 825c\\$NEW_VALUE settings/defaults/current.set
    else
      sed -i 825c\\$NEW_VALUE settings/defaults/current.set
    fi
  fi
}

do_colour_v_sin_gain() {
  CURRENT_VALUE=$(( $(sed -n 826p settings/defaults/current.set) ))
  if [ "$CURRENT_VALUE" -ge 128 ]; then
    CURRENT_VALUE=$(( $CURRENT_VALUE - 256 ))
  fi
  NEW_VALUE=$(whiptail --inputbox "Enter Pr Sin gain (-128 to 127)" 20 60 -- "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    if [ "$NEW_VALUE" -lt "0" ]; then
      NEW_VALUE=$(($NEW_VALUE + 256 ))
      sed -i 826c\\$NEW_VALUE settings/defaults/current.set
    else
      sed -i 826c\\$NEW_VALUE settings/defaults/current.set
    fi
  fi
}

do_colour_u_offset() {
  CURRENT_VALUE=$(( $(sed -n 828p settings/defaults/current.set) ))
  if [ "$CURRENT_VALUE" -ge 128 ]; then
    CURRENT_VALUE=$(( $CURRENT_VALUE - 256 ))
  fi
  NEW_VALUE=$(whiptail --inputbox "Enter Pb Offset (-128 to 127)" 20 60 -- "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    if [ "$NEW_VALUE" -lt "0" ]; then
      NEW_VALUE=$(($NEW_VALUE + 256 ))
      sed -i 828c\\$NEW_VALUE settings/defaults/current.set
    else
      sed -i 828c\\$NEW_VALUE settings/defaults/current.set
    fi
  fi
}

do_colour_v_offset() {
  CURRENT_VALUE=$(( $(sed -n 829p settings/defaults/current.set) ))
  if [ "$CURRENT_VALUE" -ge 128 ]; then
    CURRENT_VALUE=$(( $CURRENT_VALUE - 256 ))
  fi
  NEW_VALUE=$(whiptail --inputbox "Enter Pr Offset (-128 to 127)" 20 60 -- "$CURRENT_VALUE" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    if [ "$NEW_VALUE" -lt "0" ]; then
      NEW_VALUE=$(($NEW_VALUE + 256 ))
      sed -i 829c\\$NEW_VALUE settings/defaults/current.set
    else
      sed -i 829c\\$NEW_VALUE settings/defaults/current.set
    fi
  fi
}

do_colour_advanced_menu() {
  while true; do
    FUN=$(whiptail --title "Raspberry Pi GB8200 Controller v0.3" --menu "Advanced Colour Menu" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
  	"7.2.1 Enable/Disable" "Turn on/off colour expansion" \
  	"7.2.2 Y' Offset" "Change picture brightness" \
    "7.2.3 Y' Gain" "Change picture contrast" \
    "7.2.4 Pb/U Cos Gain" "Change blue-luma gain" \
    "7.2.5 Pr/V Cos Gain" "Change red-luma gain" \
    "7.2.6 Pb/U Sin Gain" "Change blue to red gain" \
    "7.2.7 Pr/V Sin Gain" "Change red to blue gain" \
    "7.2.8 Pb/U Offset" "Change blue-luma offset" \
    "7.2.9 Pr/V Offset" "Change red-luma offset" \
    3>&1 1>&2 2>&3)
    RET=$?
    if [ $RET -eq 1 ]; then
      return 0
    elif [ $RET -eq 0 ]; then
      case "$FUN" in
        7.2.1\ *) do_colour_enable ;;
  	    7.2.2\ *) do_colour_brightness ;;
        7.2.3\ *) do_colour_contrast ;;
        7.2.4\ *) do_colour_u_cos_gain ;;
        7.2.5\ *) do_colour_v_cos_gain ;;
        7.2.6\ *) do_colour_u_sin_gain ;;
        7.2.7\ *) do_colour_v_sin_gain ;;
        7.2.8\ *) do_colour_u_offset ;;
        7.2.9\ *) do_colour_v_offset ;;
        *) whiptail --msgbox "Programmer error: unrecognised option" 20 60 1 ;;
      esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
    fi
  done
}

#
#
line_format(){
  local IFS=$'\n'
  i=$((1))
  while read line ; do
    [[ $line == Header* ]] && continue
	filesWhiptail=$filesWhiptail$i" "$line" "
    i=$(($i + 1))
  done <"$1"  # Selection input argument as file for read
}

do_save() {

  NEW_VALUE=$(whiptail --inputbox "Enter Setting Name" 8 $WT_WIDTH "default" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    sudo cp -f settings/defaults/current.set "settings/"$NEW_VALUE".set" >> log.txt 2>&1
    sudo cp -f settings/defaults/current.dei "settings/deinterlace/"$NEW_VALUE".dei" >> log.txt 2>&1
  fi
}

folder_settings () {
  cd settings
}

do_nag() {
  whiptail --defaultno --yesno "Delete Settings: "$fileName 8 $WT_WIDTH 3>&1 1>&2 2>&3
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
	sudo rm -f settings/$fileName >> log.txt 2>&1
	LEN=$(( ${#fileName} - 4))
	fileName=${fileName:0:LEN}".dei"
	sudo rm -f settings/deinterlace/$fileName >> log.txt 2>&1
  fi
}

#
#
do_delete() {
  # Create a list of files to display
  folder_settings
  (find ./ -maxdepth 1 -type f -printf "%f\n" | sort) > defaults/fileList.txt
  cd ..

  line_format settings/defaults/fileList.txt
  FUN=$(whiptail --title "Select Settings File to Delete" --menu "Settings Files" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Cancel --ok-button Select \
  $filesWhiptail \
  3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    unset filesWhiptail
	return 0
  elif [ $RET -eq 0 ]; then
	fileName=$(sed -n $FUN'p' settings/defaults/fileList.txt)
    do_nag
	unset filesWhiptail
  fi
}

#
#
do_load() {
  # Create a list of files to display
  folder_settings
  (find ./ -maxdepth 1 -type f -printf "%f\n" | sort) > defaults/fileList.txt
  cd ..

  line_format settings/defaults/fileList.txt
  FUN=$(whiptail --title "Select Settings File to Load" --menu "Settings Files" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Cancel --ok-button Select \
  $filesWhiptail \
  3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    unset filesWhiptail
    return 0
  elif [ $RET -eq 0 ]; then
    fileName=$(sed -n $FUN'p' settings/defaults/fileList.txt)
	sudo cp -f settings/$fileName settings/defaults/current.set >> log.txt 2>&1
	LEN=$(( ${#fileName} - 4))
	fileName=${fileName:0:LEN}".dei"
	sudo cp -f settings/deinterlace/$fileName settings/defaults/current.dei >> log.txt 2>&1
  unset filesWhiptail
  fi
}

#
#
do_finish() {
  sed -i 1c\\true /home/pi/settings/defaults/end
  exit 0
}

# Everything needs to be run as root
if [ $(id -u) -ne 0 ]; then
  printf "Script must be run as root. Try 'sudo bash gbs-config.sh'\n"
  sed -i 1c\\true /home/pi/settings/defaults/end
  exit 1
fi

#
# Interactive use loop
#
calc_wt_size
detect_revision
# Start / Reset "adaptive_deinterlace.sh"
sed -i 1c\\true /home/pi/settings/defaults/end
sleep 0.25
sed -i 1c\\false /home/pi/settings/defaults/end
sleep 0.25
bash adaptive_deinterlace.sh > /dev/null 2>&1 &
while true; do
  FUN=$(whiptail --title "Raspberry Pi GB8200 Controller v0.3" --menu "Set-up Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
  "1  HELP" "Usage Guide" \
	"2  De-interlace" "Dynamic De-interlace Settings" \
  "3  Geometry" "Shift output image and blanking" \
  "4  Coast" "Input sync & sampling settings" \
  "5  H/V Scaling" "Change output canvas scaling" \
  "6  Sync Level" "Change output SOG/SOL sync level" \
  "7  Colour" "Change colour settigns" \
  "8  Delete Settings" "Delete a stored settings file" \
  "9  Save Settings" "Save current settings to file" \
  "10 Load Settings" "Load previous settings from file" \
  3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    do_finish
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
	  1\ *) do_help ;;
    2\ *) do_deinterlace_menu ;;
	  3\ *) do_output_geometry_menu ;;
	  4\ *) do_input_capture_menu ;;
	  5\ *) do_hv_scalling_menu ;;
	  6\ *) do_sync_level ;;
    7\ *) do_colour_menu ;;
	  8\ *) do_delete ;;
	  9\ *) do_save ;;
	  10\ *) do_load ;;
      *) whiptail --msgbox "Programmer error: unrecognised option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  else
    exit 1
    sed -i 1c\\true /home/pi/settings/defaults/end
  fi
done
