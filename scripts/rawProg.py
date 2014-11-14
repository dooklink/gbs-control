#!/usr/bin/python

# Progam All registers/I2C Address space from TVIA True View 5725
# Using NTSC Constants from GBS8200 (V4 firmware)

from Adafruit_I2C import Adafruit_I2C
import time
import sys

#print sys.argv
file = open(sys.argv[1], "r")

start = list()
lines = file.readlines()
for line in lines:
    x = int(line)
    start[len(start):] = [x]

Tiva = Adafruit_I2C(address=0x17)

for z in range(0, (len(start)/2) - 1520):
    Tiva.write8(start[z*2], start[(z*2)+1]) 
    time.sleep(0.01)

file.close()
