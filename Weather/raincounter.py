#!/usr/bin/env python2.7
import RPi.GPIO as GPIO
import os
import os.path
import time
GPIO.setmode(GPIO.BCM)


#set the muliplier for one impluse
#in this case one tick (impulse) equals 0.5mm rain
muliplier = 0.3 
#muliplier = 1 
#set the counter db name
#if the db does not exist, the program will create it
raindb = './raincounter.db'


if os.path.isfile(raindb) and os.access(raindb, os.R_OK):
        fo = open(raindb, "r+")
        newdb = False
else:
        fo = open(raindb, "w")
        newdb = True


# GPIO 23 set up as input. It is pulled up to stop false signals
GPIO.setup(23, GPIO.IN, pull_up_down=GPIO.PUD_UP)

print "raincounter started. Waiting for falling edge on GPIO 23"
# now the program will do nothing until the signal on port 23
# starts to fall towards zero. This is why we used the pullup
# to keep the signal high and prevent a false interrupt
if newdb:
        raincounter = 0
else:
        try:
                raincounter = float(fo.readline())
        except ValueError:
                newdb=True
                raincounter = 0


print time.strftime("%c") + " raincounter initial: ",raincounter," mm"
while True:
        try:
                GPIO.wait_for_edge(23, GPIO.FALLING)
                raincounter+=1*muliplier

                print time.strftime("%c") + " raincounter Rain captured: ",raincounter," mm"
                fo.seek(0)
                fo.write('%f' % raincounter)
		fo.flush()
        except KeyboardInterrupt:
                GPIO.cleanup()       # clean up GPIO on CTRL+C exit
                fo.clouse()

GPIO.cleanup()           # clean up GPIO on normal exit
fo.close()

