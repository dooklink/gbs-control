#!/bin/ash
# Read values
sudo i2cset -r -y 0 0x17 0xf0 0x03 b
VRST_VALUE=$(( (($(sudo i2cget -y 0 0x17 0x03) & 0x7f) << 4) + ($(sudo i2cget -y 0 0x17 0x02) >> 4) ))
TOP_VALUE=$(( ( (($(sudo i2cget -y 0 0x17 0x08) & 0x07) << 8) + $(sudo i2cget -y 0 0x17 0x07) -1) ))
BOTTOM_VALUE=$(( ( (($(sudo i2cget -y 0 0x17 0x09) & 0x7f) << 4) + ($(sudo i2cget -y 0 0x17 0x08) >> 4) -1) ))
if [ $BOTTOM_VALUE -eq -1 ]
then
    BOTTOM_VALUE=$(($VRST_VALUE -1 ))
fi
if [ $TOP_VALUE -eq -1 ]
then
    TOP_VALUE=$(($VRST_VALUE -1 ))
fi
# File adjust
MED=$(sed -n '777p' /home/pi/settings/defaults/current.set)
HIGH=$(sed -n '778p' /home/pi/settings/defaults/current.set)
LOW=$((TOP_VALUE & 0xff))
MED=$(( ((BOTTOM_VALUE & 0x00F) << 4) + ((TOP_VALUE >> 8) & 0x07) + ($MED & 0x08) ))
HIGH=$(( ((BOTTOM_VALUE >> 4) & 0x7f) + ($HIGH & 0x80) ))
sed -i 776c\\$LOW /home/pi/settings/defaults/current.set
sed -i 777c\\$MED /home/pi/settings/defaults/current.set
sed -i 778c\\$HIGH /home/pi/settings/defaults/current.set
# Register adjust
sudo i2cset -r -y -m 0x07 0 0x17 0x08 $((TOP_VALUE >> 8))
sudo i2cset -r -y -m 0xff 0 0x17 0x07 $((TOP_VALUE & 0xFF))
sudo i2cset -r -y -m 0x7f 0 0x17 0x09 $((BOTTOM_VALUE >> 4))
sudo i2cset -r -y -m 0xf0 0 0x17 0x08 $(( (BOTTOM_VALUE & 0x00F) << 4))
