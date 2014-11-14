#!/usr/bin/python

# Change one register in a settings file
# options list: changeSetting.py file bank reg value mask

import time
import sys

#print sys.argv  # List argument for testing
fileName = sys.argv[1]
file  = open(fileName, "r")
bank  = int(sys.argv[2], 0)
reg   = int(sys.argv[3], 0)
value = int(sys.argv[4], 0)
mask  = int(sys.argv[5], 0)

start = list()
lines = file.readlines()
for line in lines:
    x = int(line)
    start[len(start):] = [x]

file.close()
file = open(fileName, "w")

for x in range(0,len(start)):
    if x == ( bank*256 + reg):
        start[x] = (value & mask) | (start[x] & ~mask)

    file.write(str(start[x]) + '\n')

file.close()
