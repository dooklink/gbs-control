import math
import sys

Ucos = int(sys.argv[1], 0)
Usin = int(sys.argv[2], 0)
Gain = math.trunc( round( math.sqrt(Usin*Usin + Ucos*Ucos) , 0))
print Gain
