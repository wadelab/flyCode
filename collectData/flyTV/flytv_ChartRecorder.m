%Basic Chart Recorder for flyTV
%Written by RJHW 15.05.14

KbReleaseWait;

s = daq.createSession('ni');
s.DurationInSeconds = 200;
s.Rate = 1000
addAnalogInputChannel(s,'Dev3','ai0','Voltage')
s.NumberOfScans = 1000;
s.NotifyWhenDataAvailableExceeds = s.NumberOfScans;
myData=[];

while ~KbCheck
    
   
    lh = addlistener(s,'DataAvailable', @plotData);
    startBackground(s);
    s.wait;
    
end

delete (lh)



