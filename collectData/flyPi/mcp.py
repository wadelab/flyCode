# copyright Chris Elliott &  Loc Nguyen 2020

# try using export DISPLAY=0.0 if running this remotely
# importing necessary libraries
from psychopy import visual, core
import random
import numpy
import platform
import os
import matplotlib.pyplot as plt
import pdb
from datetime import datetime
import multiprocessing
from multiprocessing import Queue

if "Darwin" in platform.system():
    myHomePath = os.path.expanduser('~/pi/Data')    
    if not os.path.exists(myHomePath):
        os.makedirs(myHomePath)    
    os.chdir(myHomePath) 
    
    def read_channel(x):
        adc = x + random.randrange(1023)
        return adc
else:
    import spidev

    # Open SPI bus
    spi = spidev.SpiDev()
    spi.open(0, 0)
    spi.max_speed_hz =390000 
    
    os.chdir('/var/www/html')

    # Function to read SPI data from MCP3008 chip
    # Channel must be an integer 0-7
    def read_channel(x):
        channel = 0
        adc = spi.xfer2([1, (8 + channel) << 4, 0])
        data = ((adc[1] & 3) << 8) + adc[2]
        return data

def show_stimuli():
    total_frames = 60
    fliptimes = numpy.zeros(( 1 + 2*total_frames, 1), dtype=int)
    mywin = visual.Window([800, 600], monitor="testMonitor", units="deg", screen=0, waitBlanking = True)
    clock = core.Clock()
    frame_rate = mywin.getActualFrameRate()

    for i in range(qty):  
        
        #generate some stimuli
        frame_count = 0.0
        clock.reset(0.00)
        total_frames = 120  # 120 rows, 15 seconds, 133 ms for each j loop; 7.5 Hz
        fliptimes = numpy.zeros(( total_frames, 1), dtype=int)

        fixation = visual.GratingStim(win=mywin, mask="none", size=20, pos=[0,0], sf=0, contrast=cordinates[i,0],  phase=(0.0, 0.0))
        inverse_fixation = visual.GratingStim(win=mywin, mask="none", size=20, pos=[0,0], sf=0, contrast = - cordinates[i,0], phase=(0.0, 0.0))
        #draw the stimuli once, so we can flick back and forwards
        inverse_fixation.draw()
        mywin.flip(clearBuffer=False)
        fixation.draw()
        mywin.flip(clearBuffer=False)
        myQ.put(i)
    
        for j in range (0, total_frames): 
            # this next bit should take 1/60 * 8 sec, ie 7.5 Hz
            for k in range(stim_per_rpt):  # show each pattern for 4 frames; sample every frame
                 frame_count = frame_count + 1
                 while clock.getTime() < frame_count * 1.0/60.0:
                     pass                   
            mywin.flip(clearBuffer=False)
                      
            for k in range(stim_per_rpt):  # now show the opposite frame
                 frame_count = frame_count + 1
                 while clock.getTime() < frame_count * 1.0/60.0:
                     pass
            fliptimes[j,0] = 1000 * 1000 *mywin.flip(clearBuffer=False)
         
    # close window
    mywin.close()
    
    numpy.savetxt('myFlips.csv', fliptimes, delimiter=',', fmt='%i', newline='\n')
    os.rename("myFlips.csv", "myFlips" + Date + ".csv")
    
    print('Frame rate is ' + str(frame_rate))
    return
    
def do_ADC_with_wait(i):    
        #multiprocess the A/D conversion
    clock_for_ADC = core.Clock()
    clock_for_ADC.reset(0.0)
    
    for frame_count in range(n_rows):  # take some extra samples per frame
       while 1000 * 1000 * clock_for_ADC.getTime() < sampling_times[frame_count] :
           pass
       sampling_values[frame_count, 0] = 1000 * 1000 * clock_for_ADC.getTime()
       sampling_values[frame_count, i] = read_channel(100)
       frame_count = frame_count + 1

    return 
##############
# start program here    
Date = datetime.today().strftime('%Y-%m-%d-%H-%M-%S')
myQ = Queue()
# create an array
qty = 3 #  max types of stimulus
#sf = 0.2/0.4/0.8 gives 4/18/16 stripes
cordinates = numpy.zeros((qty, 2), dtype=float)
cordinates [0,0] = 0.2
cordinates [1,0] = 0.4
cordinates [2,0] = 0.8

# create a window
expt_clock = core.Clock()
# setting the range of coordinates and how many coordinates to produce
frame_rpts = 750 # 600 gives us 8 seconds
#pdb.set_trace()
stim_per_rpt = 4
n_rows= 2 * stim_per_rpt * frame_rpts #need 2x because we do two halves of the loop
sampling_values = numpy.zeros(( n_rows, qty + 1), dtype=int)
sampling_times = numpy.linspace(0, 1665 * float(n_rows), n_rows)
    
processes = [ ]
t = multiprocessing.Process(target=show_stimuli, args=()) # args =...
processes.append(t)
t.start()

#show_stimuli() occurs in separate thread

for i in range(qty):
    while myQ.empty():
        pass
    do_ADC_with_wait(i+1)
    myQ.get()

for one_process in processes:
    one_process.join()
    
numpy.savetxt('myData.csv', sampling_values, delimiter=',', fmt='%i', newline='\n')
os.rename("myData.csv", "myData" + Date + ".csv")
    
expt_time = expt_clock.getTime()    
print('Expt time was ' + str(expt_time))
#print('Wait time was ' + str(t_real_start))

# matplotlib graph the raw data
plt.subplot(2, 2, 1)  # (rows, columns, panel number)
plt.plot(sampling_values[:, 0], sampling_values[:, 1], linestyle='solid', marker='None')

# do an FFT
rate = 600.0 #597.6  # rate of data collection in points per second
lx = len(sampling_values)
lx = (lx // 2) + 1
ff = numpy.zeros((lx, qty), dtype=float)
for i in range(qty):
    ff[:, i] = abs(numpy.fft.rfft(sampling_values[:, i + 1]))
fx = numpy.linspace(0, rate / 2, len(ff))

plt.subplot(2, 2, 2)  # (rows, columns, panel number)
plt.plot(fx[1:], ff[1:], linestyle='solid', marker='None')

#pdb.set_trace()
# ff[15,:] nicely gives the response at 7.5Hz (x2 scale factor)
# ff_2d = numpy.reshape(ff[75], (-1, qty))
# ff_2d_tr = numpy.transpose(ff_2d)
# coords_with_data = numpy.append(cordinates, ff_2d_tr, axis=1)

#plt.subplot(2, 2, 4)  # (rows, columns, panel number)
#plt.scatter(coords_with_data[:, 0], coords_with_data[:, 1], c=coords_with_data[:, 2], s=100)

#numpy.savetxt('myCoordinates.csv', coords_with_data, delimiter=',', newline='\n')

# merge x axis (frequency data) and y FFT data
fall = numpy.insert(ff, 0, fx, axis=1)
numpy.savetxt('myFFT.csv', fall, delimiter=',', newline='\n')

plt.savefig('myGraphic.PDF')

# tidy up
os.rename("myFFT.csv", "myFFT" + Date + ".csv")
#os.rename("myCoordinates.csv", "myCoordinates" + Date + ".csv")
os.rename("myGraphic.PDF", "myGraphic" + Date + ".PDF")

    # #pdb.set_trace()
    
