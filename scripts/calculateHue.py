import math
import sys

Ucos = float(sys.argv[1])
Usin = float(sys.argv[2])
if Ucos == 0:
    if Usin < 0:
        Hue = -90
    else:
        Hue = 90
else:
    Hue = int(math.trunc( round( (180/math.pi) * math.atan(Usin/Ucos), 0) ))
print Hue
