# copyright Chris Elliott &  Loc Nguyen 2020

# importing necessary libraries
from psychopy import visual, core, filters
import random
import pdb
import numpy


# create a window
mywin = visual.Window([800, 600], monitor="testMonitor", units="deg", screen=0, waitBlanking = True)
# setting the range of coordinates and how many coordinates to produce

frame_rate = mywin.getActualFrameRate()
n_rows= 60 * 10 # 10 sec at 60 frames/sec
fliptimes = numpy.zeros(( n_rows + 1, 3), dtype=int)
expt_clock = core.Clock()

for i in range(1):  
    #generate some stimuli, f1 is a Numpy array
    f1 = filters.makeGrating(256, 90, 3, 0.0, 'sin', 0.7) # res, ori=0.0,  # in degrees  cycles=1.0,  phase=0.0,  # in degrees  gratType="sin",  contr=1.0)
    f2 = f1 * -1
    
    f3 = f1 + filters.makeGrating(256, 0, 0.5, 0.0, 'sin', 0.3) # res, ori=0.0,  # in degrees  cycles=1.0,  phase=0.0,  # in degrees  gratType="sin",  contr=1.0)
    f4 = f3 * -1
    grate = visual.GratingStim(win=mywin,  size=20,  tex= f3)
    grate_inv = visual.GratingStim(win=mywin,  size=20,  tex= f4)
   
    frame_count = 0 # one frame every 1/60 sec, every 5 frames invert grating, every 4 frames invert mask
    while frame_count < n_rows: 
        mywin.flip()
        fliptimes[frame_count,0] = 1000 * 1000 * expt_clock.getTime() 
        if frame_count % 8 < 4:
            grate.draw() #first draw ~45 ms, subsequent draws are ~1.2 ms
        else:
            grate_inv.draw()
        fliptimes[frame_count,1] = 1000 * 1000* expt_clock.getTime()        
        frame_count += 1        
        # 
        

expt_time = expt_clock.getTime()
print('Expt time was ' + str(expt_time))
print('Frame rate was ' + str(frame_rate))
numpy.savetxt("/var/www/html/data/myFlips.csv", fliptimes, delimiter=',', fmt='%i', newline='\n', header= "myData description")
# close window
mywin.close()

