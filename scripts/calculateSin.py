import math
import sys

Gain = float(sys.argv[1])
Hue = float(sys.argv[2])
Sin = int(math.trunc( round( Gain * math.sin(Hue * math.pi/180) , 0)))
print Sin