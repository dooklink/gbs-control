#!/usr/bin/python

# Write All registers/I2C Address space to TVIA True View 5725

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

if __name__ == '__main__':
  try:
    Tiva = Adafruit_I2C(address=0x17)
    #print "accsess OK"
    
    for y in range(0, 6):
        Tiva.write8(0xF0, y ) 
        time.sleep(0.01)
        for z in range(0, 15):
            bank = []
            for w in range(0, 16):
                bank.append(start[y*256 + z*16 + w])

            #print bank
            Tiva.writeList(z*16, bank)
            
  except:
    print "Error accessing default I2C bus"


file.close()
