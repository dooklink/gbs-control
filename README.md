gbs-control
===========

Raspbian based Trueview5725 i2c controller

Preliminary scripts for testing new custom settings on Trueview5725 based video processors.
GBS8200, GBS8220, HD Box Pro and others

=============
INSTALL GUIDE

The install script is designed to be used with a fresh vanilla Raspbian install.
to install or update run the following command:

wget https://raw.githubusercontent.com/dooklink/gbs-control/latest/install-gbs-control.sh && bash install-gbs-control.sh

===============
Usage

Raspberry pi will auto boot into the config menu displayed via the Green RCA Luma input on the GBS board from RPi composite output.
The Raspberry Pi must be connected to the I2C lines (SDA, SCL and GND), of the target board.
Also, the P8 jumper on the GBS82xx boards must be shorted to ensure RPi can be I2C master without interference.
Global keyboard hotkeys are preconfigured to switch between the Config Menu and the RGB Video Source.
Other tweaks can be make with the keyboard hotkeys.

================
Hotkeys

Navigation:

F1	-	Switch to Pi Menu

F2	-	Switch to Currently loaded settings

F4	-	Save current register settings to temp file (needed before menu save)

Grave/Tilde(`/~)+1 - Switch menu to RGBHV 480p (VGA)

Grave/Tilde(`/~)+2 - Switch menu to YPbPr 480p

Grave/Tilde(`/~)+3 - Switch menu to RGBHV 576p (Non-standard)

Grave/Tilde(`/~)+4 - Switch menu to YPbPr 576p

Fine adjustments:

CTRL+1	-	Increase vertical scale (if enabled)

CTRL+2	-	Decrease vertical scale (if enabled)

CTRL+3	-	Decrease horizontal scale

CTRL+4	-	Increase horizontal scale

CTRL+5	-	Move image up

CTRL+6	-	Move image down

CTRL+7	-	Move image left

CTRL+8	-	Move image right
