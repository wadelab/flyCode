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
    def read_channel(x):
        adc = x + random.randrange(1023)
        return adc
else:
    import spidev

    # Open SPI bus
    spi = spidev.SpiDev()
    spi.open(0, 0)
    spi.max_speed_hz =3900000 


    # Function to read SPI data from MCP3008 chip
    # Channel must be an integer 0-7
    def read_channel(x):
        channel = 0
        adc = spi.xfer2([1, (8 + channel) << 4, 0])
        data = ((adc[1] & 3) << 8) + adc[2]
        return data

Date = datetime.today().strftime('%Y-%m-%d-%H-%M-%S')
#if not os.path.exists('/home/pi/Data'):
#        os.mkdir('/home/pi/Data')
#os.chdir('/home/pi/Data')
os.chdir('/var/www/html')

# create an array
qty = 3 #  max types of stimulus
#sf = 0.2/0.4/0.8 gives 4/18/16 stripes
cordinates = numpy.zeros((qty, 2), dtype=float)
cordinates [0,0] = 0.2
cordinates [1,0] = 0.4
cordinates [2,0] = 0.8

# create a window
mywin = visual.Window([800, 600], monitor="testMonitor", units="deg", screen=0)
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
frame_rpts = 45
stim_per_rpt = 4
extra_samples_per_frame = 1
sampling_values = numpy.zeros(((1 + extra_samples_per_frame) * frame_rpts * stim_per_rpt * 2, qty + 1), dtype=int)

for i in range(qty):  # show all dots one after another
    clock.reset(0.00)
    frame_count = 0
    fixation = visual.GratingStim(win=mywin, mask="none", size=20, pos=[0,0], sf=0, contrast=cordinates[i,0],  phase=(0.0, 0.0))
    inverse_fixation = visual.GratingStim(win=mywin, mask="none", size=20, pos=[0,0], sf=0, contrast = - cordinates[i,0], phase=(0.0, 0.0))

    fixation.draw()

    mywin.flip()

    inverse_fixation.draw()



    for j in range(frame_rpts):  # 15 times should give us 2 sec of flicker
        # this next bit should take 1/60 * 8 sec, ie 7.5 Hz
        for k in range(stim_per_rpt):  # show each pattern for 4 frames; sample every frame
            # create some stimuli
            
            sampling_values[frame_count, i + 1] = read_channel(100)
            sampling_values[frame_count, 0] = 1000 * clock.getTime()
            frame_count = frame_count + 1
            timer.reset(0.00)
            for l in range(extra_samples_per_frame):  # take some extra samples per frame
                while timer.getTime() < 0.0083:
                    myCount = myCount + 1

                sampling_values[frame_count, i + 1] = read_channel(100)
                sampling_values[frame_count, 0] = 1000 * clock.getTime()
                frame_count = frame_count + 1
                timer.reset(0.00)
            mywin.flip()
        for k in range(stim_per_rpt):  # now show the opposite frame
#            inverse_fixation.draw()
            sampling_values[frame_count, i + 1] = read_channel(-100)
            sampling_values[frame_count, 0] = 1000 * clock.getTime()
            frame_count = frame_count + 1
            timer.reset(0.00)
            for l in range(extra_samples_per_frame):
                while timer.getTime() < 0.0083:
                    myCount = myCount + 1
                sampling_values[frame_count, i + 1] = read_channel(-100)
                sampling_values[frame_count, 0] = 1000 * clock.getTime()
                frame_count = frame_count + 1
                timer.reset(0.00)
            mywin.flip()

expt_time = expt_clock.getTime()
# close window
mywin.close()

numpy.savetxt('myData.csv', sampling_values, delimiter=',', fmt='%i', newline='\n')

print('Frame rate is ' + str(frame_rate))
print('Expt time was ' + str(expt_time))

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
