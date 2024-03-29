#!/home/pi/venv/bin/python
# copyright Chris Elliott &  Loc Nguyen 2020/21

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



import spidev
os.chdir('/var/www/html/data')
# Open SPI bus
spi = spidev.SpiDev()
spi.open(0, 0)
spi.max_speed_hz = 390000  



# Function to read SPI data from MCP3008 chip
# Channel must be an integer 0-7
def read_channel(x):
    channel = 2
#    adc = spi.xfer2([1, (8 + channel) << 4, 0])
#    data = ((adc[1] & 3) << 8) + adc[2]
    data = random.randrange(1023)
    return data

def show_stimuli():
    total_frames = 60
    fliptimes = numpy.zeros(( 1 + 2*total_frames, 1), dtype=int)
    mywin = visual.Window([800, 600], monitor="testMonitor", units="deg", screen=0, waitBlanking = True)
    clock = core.Clock()
    frame_rate = mywin.getActualFrameRate()

    for i in range(qty):  
        f = open ("/var/www/html/data/status.html", "w")
        f.write ("<!DOCTYPE html><html><head><meta http-equiv=\"refresh\" content=\"5\"></head>")
        f.write ("<body><h3>")
        f.write (" Sampling (" + str(i) +  " of " + str(qty) + ")<BR> \n")
        f.write ("</h3>")
        if (i>0):
            f.write (' <img src="../../data/myLastData.png" alt="recording last trace"> ')
        f.write ("</body></html>")
        f.close() 
        
        #generate some stimuli
        frame_count = 0.0
        clock.reset(0.00)
        total_frames = 120  # 120 rows, 15 seconds, 133 ms for each j loop; 7.5 Hz
        fliptimes = numpy.zeros(( total_frames, 1), dtype=int)

        fixation =         visual.GratingStim(win=mywin, mask="none", size=20, pos=[0,0], sf=cordinates[i,1], contrast = cordinates[i,0],   phase=(0.0, 0.0))
        inverse_fixation = visual.GratingStim(win=mywin, mask="none", size=20, pos=[0,0], sf=cordinates[i,1], contrast = - cordinates[i,0], phase=(0.0, 0.0))
        null_fixation =    visual.GratingStim(win=mywin, mask="none", size=20, pos=[0,0], sf=0,               contrast = 0,                 phase=(0.0, 0.0))
        
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
        # draw 50% here durin wait
        null_fixation.draw()
        mywin.flip(clearBuffer=True)
        core.wait(2) # 2 sec rest between stimuli     
           
    # numpy.savetxt("myFlips" + Date + ".csv", fliptimes, delimiter=',', fmt='%i', newline='\n', header= myHeader)
    # close window
    mywin.close()
    print('Frame rate is ' + str(frame_rate))
    return
    
def do_ADC_with_wait(i):    
        #multiprocess the A/D conversion
    clock_for_ADC = core.Clock()
    clock_for_ADC.reset(0.0)
    
    for frame_count in range(1, n_rows):  # this is enough to still be in the stimulus
       while 1000 * 1000 * clock_for_ADC.getTime() < sampling_times[frame_count] :
           pass
       sampling_values[frame_count, 0] = 1000 * 1000 * clock_for_ADC.getTime()
       sampling_values[frame_count, i] = read_channel(100)
       frame_count = frame_count + 1

    return 
##############################################################################################################################
# start program here    
##############################################################################################################################

myHeader = os.environ.get( 'QUERY_STRING' )  #return empty header if  no environment variable
if myHeader is None:
    myHeader = 'Test_String_stripes'


Date = datetime.today().strftime('%Y-%b-%d-%H-%M-%S')
myQ = Queue()

# create an array of stimulus parameters
#these ought not to be less than 1%, or they won't work as integers later

if 'stripes' in myHeader:
    qty = 5 #  max types of stimulus
    cordinates = numpy.zeros((qty, 2), dtype=float)
    #sf = 0.2/0.4/0.8 gives 4/18/16 stripes
    cordinates [0,1] = 0.8
    cordinates [1,1] = 0.1
    cordinates [2,1] = 0.4
    cordinates [3,1] = 1.0
    cordinates [4,1] = 0.2
    cordinates [:,0] = 0.8 # set the contrast of the stripes
    proCol = 1
else:
    # simple CRF
    qty = 7 #  max types of stimulus
    cordinates = numpy.zeros((qty, 2), dtype=float)
    cordinates [0,0] = 0.8
    cordinates [1,0] = 0.01
    cordinates [2,0] = 0.4
    cordinates [3,0] = 0.1
    cordinates [4,0] = 0.2
    cordinates [5,0] = 0.07
    cordinates [6,0] = 1.0
    proCol = 0
    
    if 'uick' in myHeader: # just do a quick test to see if it works
        qty = 1


# create a window
expt_clock = core.Clock()
# setting the range of coordinates and how many coordinates to produce
frame_rpts = 750 # 600 gives us 8 seconds
#pdb.set_trace()
stim_per_rpt = 4
n_rows= 2 * stim_per_rpt * frame_rpts + 1 #need 2x because we do two halves of the loop; +1 to allow for stimuli in first row
sampling_values = numpy.zeros(( n_rows, qty + 1), dtype=int)
sampling_times = numpy.linspace(0, 1665 * float(n_rows), n_rows)

##################################################################################################
#start multithread
##################################################################################################    
processes = [ ]
t = multiprocessing.Process(target=show_stimuli, args=()) # args =...
processes.append(t)
t.start()

#show_stimuli() occurs in separate thread

for i in range(qty):
    while myQ.empty():
        pass
    do_ADC_with_wait(i+1)
    plt.plot(sampling_values[2:250,0] / 1000, sampling_values[2:250, i+1], linestyle='solid', marker='None')
    plt.xlabel('time (ms)') 
    plt.savefig("myLastData.png")
    plt.close()
    myQ.get()

for one_process in processes:
    one_process.join()
    
##################################################################################################
#process collected data
##################################################################################################   
expt_time = expt_clock.getTime()    
print('Expt time was ' + str(expt_time))
if qty == 1:
    f = open ("/var/www/html/data/status.html", "w")
    f.write ("<!DOCTYPE html><html><head></head>")
    f.write ("<body><h3>")
    f.write (" Sampling done<BR> \n")
    f.write ("</h3>")
    f.write (' <img src="../../data/myLastData.png" alt="recorded last trace"> ')
    f.write ("</body></html>")
    f.close() 
    quit
#print('Wait time was ' + str(t_real_start))
#save the stimuli (as %) in first row of data
sampling_values[0,1:] = 100 * numpy.transpose(cordinates[:,proCol])
numpy.savetxt("myData" + Date + ".csv", sampling_values, delimiter=',', fmt='%i', newline='\n', header= myHeader)
 

# matplotlib graph the raw data
plt.subplot(2, 2, 1)  # (rows, columns, panel number)
plt.plot(sampling_values[1:500, 0]/1000, sampling_values[1:500, 1:3], linestyle='solid', marker='None')
plt.xlabel('time (ms)')

# do an FFT
rate = 600.0 #597.6  # rate of data collection in points per second
lx = len(sampling_values)
lx = (lx // 2) + 1
ff = numpy.zeros((lx, qty), dtype=float)
for i in range(qty):
    ff[:, i] = abs(numpy.fft.rfft(sampling_values[:, i + 1])) / 1000.0
fx = numpy.linspace(0, rate / 2, len(ff))
#save the stimuli in first row of FFT
ff[0] = 100 * numpy.transpose(cordinates[:,proCol])

#plot the fft up to 60Hz
plt.subplot(2, 2, 2)  # (rows, columns, panel number)
plt.plot(fx[1:601], ff[1:601], linestyle='solid', marker='None')
plt.xlabel('frequency (Hz)')




#pdb.set_trace() 
#ff[75,:] nicely gives the response at 1F1, 7.5Hz (x10 scale factor)
ff_2d = numpy.reshape(ff[75], (-1, qty))
ff_2d_tr = numpy.transpose(ff_2d)
coords_with_data = numpy.append(cordinates, ff_2d_tr, axis=1)
#and try with 2F1
ff_2d = numpy.reshape(ff[150], (-1, qty))
ff_2d_tr = numpy.transpose(ff_2d)
coords_with_data = numpy.append(coords_with_data, ff_2d_tr, axis=1)
coords_with_data[:, proCol] = 100 * coords_with_data[:, proCol]
coords_with_data = coords_with_data[coords_with_data[:, proCol].argsort()] # sort by first (zero) column see https://stackoverflow.com/questions/2828059/sorting-arrays-in-numpy-by-column

#pdb.set_trace()
plt.subplot(2, 2, 3 + proCol)  # (rows, columns, panel number)
plt.plot(coords_with_data[:, proCol], coords_with_data[:, 2], 'go-', label ='1F1') #, green dots and solid line
plt.plot(coords_with_data[:, proCol], coords_with_data[:, 3], 'bo-', label ='2F1') #, blue  dots and solid line
ymax = 1.2 * max (numpy.max(coords_with_data[:, 2]), numpy.max(coords_with_data[:, 3]))
plt.ylim(0,ymax)

if proCol == 0:
    plt.xlabel('contrast (%)')
    plt.xlim(0.8,110)
else:
    plt.xlabel('spatial frequency (? units)')   
    plt.xlim(8,110)

plt.xscale('log')
plt.legend()

plt.suptitle(myHeader)
plt.tight_layout(2)

# merge x axis (frequency data) and y FFT data
fall = numpy.insert(ff, 0, fx, axis=1)
numpy.savetxt('myFFT' + Date + '.csv', fall, delimiter=',', newline='\n', header= myHeader)

plt.savefig("myGraphic" + Date + ".PDF")

f = open ("/var/www/html/data/status.html", "w")
f.write ("<!DOCTYPE html><html><head></head>")
f.write ("<body><h3>")
f.write (" Sampling completed (" + str(i) +  ")<BR> </h3>\n")
f.write("<a href=\"../../index.html\">Starter page </a><BR><BR>")
f.write("<a href=\"../../data/?C=M;O=D\"> Data Directory</a>")
f.write("</body></html>")
f.close()   

#pdb.set_trace()
    
