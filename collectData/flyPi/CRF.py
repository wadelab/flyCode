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
myStimuli = []

for i in range(1):  
    #generate some stimuli, fHoriz and fVert is a Numpy array
    fHoriz = filters.makeGrating(256, 90, 1.0, 0.0, 'sin', 0.7) # res, ori=0.0,  # in degrees  cycles=1.0,  phase=0.0,  # in degrees  gratType="sin",  contr=1.0)
    fVert =  filters.makeGrating(256, 0, 1.0, 0.0, 'sin', 0.3) # res, ori=0.0,  # in degrees  cycles=1.0,  phase=0.0,  # in degrees  gratType="sin",  contr=1.0)
    
    
    # loop through 60 stimuli; every 6 frames invert grating, every 5 frames invert mask
    for j in range(60):
        if j % 12 < 6 :
            myStimuli.append(visual.GratingStim(win=mywin,  size=20,  tex = fVert))
        else :
            myStimuli.append(visual.GratingStim(win=mywin,  size=20,  tex = -fVert))
 
    # pdb.set_trace()
    
    frame_count = 0 # one frame every 1/60 sec, first show of grating takes my Pi 45 ms, then 1 ms for second show
    while frame_count < n_rows: 
        mywin.flip()
        fliptimes[frame_count,0] = 1000 * 1000 * expt_clock.getTime() 
        myStimuli[frame_count % 60].draw()
        fliptimes[frame_count,1] = 1000 * 1000 * expt_clock.getTime()        
        frame_count += 1        
        # 
        

expt_time = expt_clock.getTime()
print('Expt time was ' + str(expt_time))
print('Frame rate was ' + str(frame_rate))
numpy.savetxt("/var/www/html/data/myFlips.csv", fliptimes, delimiter=',', fmt='%i', newline='\n', header= "myData description")
# close window
mywin.close()

