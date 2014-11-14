#!/usr/bin/python

# Dump All registers/I2C Address space from TVIA True View 5725

from Adafruit_I2C import Adafruit_I2C
import time

if __name__ == '__main__':
  try:
    Tiva = Adafruit_I2C(address=0x17)
    

        
    
    for y in range(0, 6):
        Tiva.write8(0xF0, y ) 
        #print Tiva.readU8(0xF0)
        time.sleep(0.01)
        
        for x in range(0, 16):
            bank = Tiva.readList(x*16, 16)
            for z in range(0,16):
                print bank[z]
                
        #print "\n"
    
  except:
    print "Error accessing default I2C bus"
