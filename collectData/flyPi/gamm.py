#!/home/pi/venv/bin/python
# copyright Chris Elliott &  Loc Nguyen 2020/21

# importing necessary libraries
from psychopy import visual, core

import pdb
import sys

import faulthandler
faulthandler.enable()


def show_stimuli(c1):
    mywin = visual.Window([800, 600], monitor="testMonitor", units="deg", screen=0, color = (c1,c1,c1), waitBlanking = True)
    core.wait(15) #seconds

    # close window
    mywin.close()
    print('Intensity was ' + str(c1))
    return


##############################################################################################################################
# start program here    
##############################################################################################################################


pdb.set_trace()
if (len(sys.argv) > 0) :
    show_stimuli(sys.argv[1]) 
else :
    print("No argument for intensity supplied");

#pdb.set_trace()
    
