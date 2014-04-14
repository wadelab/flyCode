function flytv_dumpData(src,event)
% fucntion flytv_dumpData
% This is a listener function for the data acquisition toolbox
% It just dumps the event data into a global variable
global gl; % At the moment, this is a quick and dirty way to get data back from a listener.
 
gl=event;
