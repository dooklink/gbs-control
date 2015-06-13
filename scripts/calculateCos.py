import math
import sys

Gain = float(sys.argv[1])
Hue = float(sys.argv[2])
Cos = int(math.trunc( round( Gain * math.cos(Hue * math.pi/180) , 0)))
print Cos