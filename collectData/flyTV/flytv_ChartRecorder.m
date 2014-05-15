%Basic Chart Recorder for flyTV
%Written by RJHW 15.05.14

KbReleaseWait;

s = daq.createSession('ni');
s.DurationInSeconds = 10;
addAnalogInputChannel(s,'Dev3','ai0','Voltage')
s.NumberOfScans = 500;
s.NotifyWhenDataAvailableExceeds = s.NumberOfScans;
myData=[];

while ~KbCheck
   
    addlistener(s,'DataAvailable', @plotData);
    axis([-inf,inf,-50,50])
    startBackground(s);
    s.wait
   
end

delete (lh)



