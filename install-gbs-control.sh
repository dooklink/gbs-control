#!/bin/ash
# Install script for Trueview 5725 control (GBS8200, GBS8220, HD9000, HD Box Pro etc)

DIR=$HOME
echo -e "\nInstall location is: "$DIR

# Update sources and install I2C components.
echo -e "\nUpdating sources & installing i2c utils:"
sudo apt-get update
sudo apt-get install -y i2c-tools libi2c-dev python-smbus

# Get latest stable version from GitHub
echo -e "\nDownloading latest working version:"
cd $DIR
wget https://raw.githubusercontent.com/dooklink/gbs-control/latest/gbs-control.zip

# Unpack scripts & default settings
echo -e "\nUnpacking zip package:"
unzip -oq $DIR/gbs-control.zip

echo -e "\nRemove zip package:"
rm $DIR/gbs-control.zip

# Patch /etc/inittab to allow for automatic login 
# and to use xterm-mono for B&W (monochrome) interactive terminal.
echo -e "\nApply patch to /etc/inittab for auto login and monochrome terminal:"
sudo patch -bN /etc/inittab $DIR/scripts/patch.inittab

# Move Triggerhappy conf files to /etc/triggerhappy/
#cp thd/* /etc/triggerhappy/triggers.d/*

# Add required scripts for automatic start-up.
echo -e "\nApply patch to .profile for bootup scripts:"
sudo patch -bN $DIR/.profile $DIR/scripts/patch.profile

# Reboot
echo -e "\nNow rebooting system"
sync
sudo reboot
exit 0
