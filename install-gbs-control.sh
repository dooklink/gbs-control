#!/bin/ash
# Install script for Trueview 5725 control (GBS8200, GBS8220, HD9000, HD Box Pro etc)

# Update sources and install I2C components.
apt-get update
apt-get install -y i2c-tools libi2c-dev python-smbus

# Get latest stable version from GitHub
cd ~/
wget https://raw.githubusercontent.com/dooklink/gbs-control/latest/gbs-control.zip

# Unpack scripts & default settings
unzip -o gbs-control-latest.zip

# Patch /etc/inittab to allow for automatic login 
# and to use xterm-mono for B&W (monochrome) interactive terminal.
patch -b /etc/inittab ~/scripts/inittab.patch

# Move Triggerhappy conf files to /etc/triggerhappy/
#cp thd/* /etc/triggerhappy/triggers.d/*

# Add required scripts for automatic start-up.
#patch -b /etc/profile profile.patch

# Reboot
sync
reboot
exit 0

