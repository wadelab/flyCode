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

if "Darwin" in platform.system():
    myHomePath = os.path.expanduser('~/pi/Data')    
    if not os.path.exists(myHomePath):
        os.makedirs(myHomePath)    
    os.chdir(myHomePath) 
    
    def read_channel(t, s, x):
        t.reset(0.0)
        adc = x + random.randrange(1023)
        while t.getTime () < 0.0017 : #1.0/ (60.0 * (1+s)) :
            pass
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
    def read_channel(t, s, x):
        t.reset(0.0)
        channel = 0
        adc = spi.xfer2([1, (8 + channel) << 4, 0])
        data = ((adc[1] & 3) << 8) + adc[2]
        while t.getTime () < 0.0017 : #
            pass
        return data

Date = datetime.today().strftime('%Y-%m-%d-%H-%M-%S')



# create an array
qty = 3 #  max types of stimulus
#sf = 0.2/0.4/0.8 gives 4/18/16 stripes
cordinates = numpy.zeros((qty, 2), dtype=float)
cordinates [0,0] = 0.2
cordinates [1,0] = 0.4
cordinates [2,0] = 0.8

# create a window
mywin = visual.Window([800, 600], monitor="testMonitor", units="deg", screen=0, waitBlanking = False)
clock = core.Clock()
expt_clock = core.Clock()
timer = core.Clock()
# setting the range of coordinates and how many coordinates to produce
frame = 7.5
seconds_stim = 1
frame_rate = mywin.getActualFrameRate()

i = 0
#while i < qty: # need to make this randomise the order of the stimuli 
    #x = random.randrange(*rangeX)
    #y = random.randrange(*rangeY)
    #cordinates[i, :] = [x, y]
    #i += 1

myCount = 0
frame_rate = mywin.getActualFrameRate()
frame_rpts = 15

#pdb.set_trace()
stim_per_rpt = 4
samples_per_frame = 10
n_rows= 2 * samples_per_frame  * stim_per_rpt * frame_rpts #need 2x because we do two halves of the loop
sampling_values = numpy.zeros(( n_rows, qty + 1), dtype=int)

for i in range(qty):  
    #generate some stimuli
    frame_count = 0
    
    fixation = visual.GratingStim(win=mywin, mask="none", size=20, pos=[0,0], sf=0, contrast=cordinates[i,0],  phase=(0.0, 0.0))
    inverse_fixation = visual.GratingStim(win=mywin, mask="none", size=20, pos=[0,0], sf=0, contrast = - cordinates[i,0], phase=(0.0, 0.0))
    #draw the stimuli once, so we can flick back and forwards
    inverse_fixation.draw()
    mywin.flip(clearBuffer=False)
    fixation.draw()
    mywin.flip(clearBuffer=False)
    clock.reset(0.00)

    while frame_count < n_rows: #for j in range(frame_rpts):  # 15 times should give us 2 sec of flicker
        # this next bit should take 1/60 * 8 sec, ie 7.5 Hz
        for k in range(stim_per_rpt):  # show each pattern for 4 frames; sample every frame

            for l in range(samples_per_frame):  # take some extra samples per frame
               sampling_values[frame_count, 0] = 1000 * 1000 * clock.getTime()
               sampling_values[frame_count, i + 1] = read_channel(timer, samples_per_frame, 100)
               frame_count = frame_count + 1
               
        mywin.flip(clearBuffer=False)
          
        for k in range(stim_per_rpt):  # now show the opposite frame
            for l in range(samples_per_frame):
               sampling_values[frame_count, 0] = 1000 * 1000 * clock.getTime()
               sampling_values[frame_count, i + 1] = read_channel(timer, samples_per_frame, -100)
               frame_count = frame_count + 1
            
        mywin.flip(clearBuffer=False)
        



expt_time = expt_clock.getTime()
# close window
mywin.close()

numpy.savetxt('myData.csv', sampling_values, delimiter=',', fmt='%i', newline='\n')

print('Frame rate is ' + str(frame_rate))
print('Expt time was ' + str(expt_time))
#print('sample time was ' + str (1.0/ (60.0 * samples_per_frame)))
# matplotlib graph the raw data
plt.subplot(2, 2, 1)  # (rows, columns, panel number)
plt.plot(sampling_values[:, 0], sampling_values[:, 1], linestyle='solid', marker='None')

# do an FFT
rate = 120.  # rate of data collection in points per second
lx = len(sampling_values)
lx = (lx // 2) + 1
ff = numpy.zeros((lx, qty), dtype=float)
for i in range(qty):
    ff[:, i] = abs(numpy.fft.rfft(sampling_values[:, i + 1]))
fx = numpy.linspace(0, rate / 2, len(ff))

plt.subplot(2, 2, 2)  # (rows, columns, panel number)
plt.plot(fx[1:], ff[1:], linestyle='solid', marker='None')

# ff[15,:] nicely gives the response at 7.5Hz (x2 scale factor)
ff_2d = numpy.reshape(ff[15], (-1, qty))
ff_2d_tr = numpy.transpose(ff_2d)
coords_with_data = numpy.append(cordinates, ff_2d_tr, axis=1)

#plt.subplot(2, 2, 4)  # (rows, columns, panel number)
#plt.scatter(coords_with_data[:, 0], coords_with_data[:, 1], c=coords_with_data[:, 2], s=100)

#numpy.savetxt('myCoordinates.csv', coords_with_data, delimiter=',', newline='\n')

# merge x axis (frequency data) and y FFT data
fall = numpy.insert(ff, 0, fx, axis=1)
numpy.savetxt('myFFT.csv', fall, delimiter=',', newline='\n')

plt.savefig('myGraphic.PDF')

# tidy up
os.rename("myFFT.csv", "myFFT" + Date + ".csv")
os.rename("myData.csv", "myData" + Date + ".csv")
#os.rename("myCoordinates.csv", "myCoordinates" + Date + ".csv")
os.rename("myGraphic.PDF", "myGraphic" + Date + ".PDF")

#pdb.set_trace()
