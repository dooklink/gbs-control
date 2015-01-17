#!/bin/ash
# Install script for Trueview 5725 control (GBS8200, GBS8220, HD9000, HD Box Pro etc)

DIR=$HOME
echo -e "\nInstall location is: "$DIR

# Update sources and install I2C components.
echo -e "\nUpdating sources & installing i2c utils:"
sudo apt-get update
sudo apt-get install -y i2c-tools libi2c-dev python-smbus

# Get latest stable version from GitHub
echo -e "\nDownloading current release version:"
cd $DIR
wget https://raw.githubusercontent.com/dooklink/gbs-control/master/gbs-control.zip

# Unpack scripts & default settings
echo -e "\nUnpacking zip package:"
unzip -oq $DIR/gbs-control.zip

echo -e "\nRemove zip package:"
rm $DIR/gbs-control.zip

# Patch /etc/inittab to allow for automatic login.
# and to use xterm-mono for B&W (monochrome) interactive terminal.
echo -e "\nApply patch to /etc/inittab for auto login and monochrome terminal:"
sudo patch -bN -F 6 /etc/inittab $DIR/scripts/patch.inittab

# Patch /etc/modules & /etc/modprobe.d/raspi-blacklist.conf for i2c use
echo -e "\nApply patch to /etc/modules for kernal i2c modules:"
sudo patch -bN -F 6 /etc/modules $DIR/scripts/patch.modules
echo -e "\nApply patch to /etc/modprobe.d/raspi-blacklist.conf to allow i2c use:"
sudo patch -bN -F 6 /etc/modprobe.d/raspi-blacklist.conf $DIR/scripts/patch.raspi-blacklist.conf

# Patch /etc/default/triggerhappy to use root user
echo -e "\nApply patch to /etc/default/triggerhappy to use root"
sudo patch -bN -F 6 /etc/default/triggerhappy $DIR/scripts/patch.triggerhappy

# Move triggerhappy files to /etc/triggerhappy/triggers.d
echo -e "\nCopy triggerhappy hotkey conf files:"
REVISION=$(cat /proc/cpuinfo | grep revision)
LEN=${#REVISION}
POS=$((LEN -1))
REV=${REVISION:POS}
if [ "$REV" = "0" ] || [ "$REV" = "1" ]; then
    echo -e "Revision 1 detected"
	sudo cp thd/triggerhappy_rev1/* /etc/triggerhappy/triggers.d/
else
    echo -e "Revision 2 detected"
	sudo cp thd/triggerhappy/* /etc/triggerhappy/triggers.d/
fi

# Add required scripts for automatic start-up.
echo -e "\nApply patch to .profile for bootup scripts:"
patch -bN -F 6 $DIR/.profile $DIR/scripts/patch.profile

# Replace config.txt to ensure booting with composite.
echo -e "\nReplace /boot/config.txt for Luma output settings:"
sudo cp /boot/config.txt /boot/config.txt.bak
sudo rm /boot/config.txt
sudo cp $DIR/scripts/config.txt /boot/config.txt

# Reboot
echo -e "\nNow rebooting system"
sync
sudo reboot
exit 0
