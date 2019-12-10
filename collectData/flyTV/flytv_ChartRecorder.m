close all
clear all

%Basic Chart Recorder for flyTV
%Written by RJHW 15.05.14
TWO_CHANNEL_SYSTEM=1;

KbReleaseWait;
whichScreen=1
s = daq.createSession('ni');
s.DurationInSeconds = 200;
s.Rate = 1000
   addAnalogInputChannel(s,'Dev4',0,'Voltage')
if(TWO_CHANNEL_SYSTEM==1)
    addAnalogInputChannel(s,'Dev4',1,'Voltage')
end

s.NumberOfScans = 1000;
s.NotifyWhenDataAvailableExceeds = s.NumberOfScans;
myData=[];

while ~KbCheck
    
   
    lh = addlistener(s,'DataAvailable', @plotData);
    startBackground(s);
    s.wait;
    
end

delete (lh)



