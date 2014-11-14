#!/bin/bash
# Turn off all output video enhancements
# Apart from output oversampling interpolation
# Select register set 3

sudo i2cset -y -r 1 0x17 0xf0 0x03 b

# 9.1 Ouput formater
 # Ouput format sets output timing / resolution

# 9.2 3D noise reduction

# select manual motion index
sudo i2cset -y -r -m 0x80 1 0x17 0x53 0x80
# Attempt global still bypass
sudo i2cset -y -r -m 0xc0 1 0x17 0x55 0x00
# Set gain for less noise reduction
sudo i2cset -y -r 1 0x17 0x54 0xff
# Set offsets to set motion index in manual mode
sudo i2cset -y -r -m 0x3f 1 0x17 0x53 0xff
sudo i2cset -y -r -m 0x3f 1 0x17 0x56 0xff
# VT filter bypass & mi threshold setting
sudo i2cset -y -r -m 0xb0 1 0x17 0x52 0xb0
sudo i2cset -y -r -m 0x0f 1 0x17 0x55 0x0f

# 9.3 H/V Scaling Up
 # Needed for output scaling

# 9.4 Video Enhancement

# 9.4.1 2D Peaking
# Bypass peaking
sudo i2cset -y -r -m 0x0b 1 0x17 0x4e 0x0b
sudo i2cset -y -r 1 0x17 0x44 0x00
sudo i2cset -y -r 1 0x17 0x45 0x00
sudo i2cset -y -r 1 0x17 0x46 0x00
sudo i2cset -y -r 1 0x17 0x47 0x00
sudo i2cset -y -r 1 0x17 0x48 0x00
sudo i2cset -y -r 1 0x17 0x49 0x00
sudo i2cset -y -r 1 0x17 0x4a 0x00
sudo i2cset -y -r 1 0x17 0x4b 0x00
sudo i2cset -y -r 1 0x17 0x4c 0x00
sudo i2cset -y -r 1 0x17 0x4d 0x00

# 9.4.2 Chroma Transient improvement
# bypass uv step response control
sudo i2cset -y -r -m 0x80 1 0x17 0x2b 0x80

# 9.4.3 Black/White level expansion
# bypass Y' saturation
sudo i2cset -y -r -m 0x01 1 0x17 0x2a 0x01
sudo i2cset -y -r -m 0x80 1 0x17 0x56 0x80

# 9.4.4 Color enhancement

# 9.4.4.1 Non-linear saturation bypass
sudo i2cset -y -r -m 0x0c 1 0x17 0x60 0x04

# 9.4.4.2 Skin tone correction bypass
sudo i2cset -y -r -m 0x3f 1 0x17 0x31 0x20

# 9.4.4.3 Color Improvement bypass
