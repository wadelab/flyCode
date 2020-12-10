# copyright Chris Elliott &  Loc Nguyen 2020

# importing necessary libraries
from psychopy import visual, core
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
    #generate some stimuli
    frame_count = 0 # one frame every 1/60 sec, every 5 frames invert grating, every 4 frames invert mask
    #sf = 0.2/0.4/0.8 gives 4/18/16 stripes; 30% contrast
    grate = visual.GratingStim(win=mywin,  size=20,  sf=0.8, contrast=0.3)
    grate_inv = visual.GratingStim(win=mywin,  size=20,  sf=0.8, contrast=-0.3)
    mask  = visual.GratingStim(win=mywin,  size=20,  sf=0.4, contrast=0.3, ori = 90, opacity=0.5)
    mask_inv  = visual.GratingStim(win=mywin,  size=20,  sf=0.4, contrast=-0.3, ori = 90, opacity=0.5)


    while frame_count < n_rows: 
        mywin.flip()
        fliptimes[frame_count,0] = 1000 * 1000 * expt_clock.getTime() 
        frame_count += 1
        if frame_count % 5 == 0:
            grate.contrast = - grate.contrast
        if frame_count % 8 < 4:
            mask.draw()
        else:
            mask_inv.draw()
        fliptimes[frame_count,1] = 1000 * 1000* expt_clock.getTime()        
        
        # 
        

expt_time = expt_clock.getTime()
print('Expt time was ' + str(expt_time))
print('Frame rate was ' + str(frame_rate))
numpy.savetxt("/var/www/html/data/myFlips.csv", fliptimes, delimiter=',', fmt='%i', newline='\n', header= "myData description")
# close window
mywin.close()

