#!/bin/ash

# File adjust
LOW=$(sed -n '792p' /home/pi/settings/defaults/current.set)
HIGH=$(sed -n '793p' /home/pi/settings/defaults/current.set)
NEW_VALUE=$(( ( (($HIGH & 0x7f) << 4) + ($LOW >> 4) +1) ))
HIGH=$(( ((NEW_VALUE >> 4) & 0x7f) + ($HIGH & 0x80) ))
LOW=$(( ((NEW_VALUE << 4) & 0xf0) + ($LOW & 0x0f) ))
sed -i 792c\\$LOW /home/pi/settings/defaults/current.set
sed -i 793c\\$HIGH /home/pi/settings/defaults/current.set
# Register adjust
sudo i2cset -r -y 1 0x17 0xf0 0x03 b 
NEW_VALUE=$(( ( (($(sudo i2cget -y 1 0x17 0x18) & 0x7f) << 4) + ($(sudo i2cget -y 1 0x17 0x17) >> 4) +1) )) 
sudo i2cset -r -y -m 0x7f 1 0x17 0x18 $((NEW_VALUE >> 4))
sudo i2cset -r -y -m 0xf0 1 0x17 0x17 $(( (NEW_VALUE & 0x00F) << 4))
