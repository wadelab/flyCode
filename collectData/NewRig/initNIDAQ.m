function [ao,ai]=initNIDAQ(aoVal)
% function initNIDAQ()
% Initializes the NIDAQ board
% Sets all the LEDs to 0 output (5.5 v)
%$ Returns analog input and output handles 
daqreset;
%% Board initialization
if (~isempty(daqfind))
    stop(daqfind)
end

% Get some information about what boards are available. This should not
% change so it's just a check.
hw = daqhwinfo('nidaq');
hw.InstalledBoardIds
hw.BoardNames


% ...and an analogue output object. 
ao = analogoutput('nidaq','Dev1');

% Cycle through ao, setting everything to aoVal 
aoVal=aoVal(:);

if (length(aoVal)==1)
    aoVal=repmat(aoVal,4,1);
end

for t=0:3
    disp(t);
    
    chan=addchannel(ao,t);   
    set(ao,'SampleRate',10000);


    set(ao,'TriggerType','Manual');
    nulldat=ones(128,1)*aoVal(t+1); % Turn the LED to mean level at the end
    putdata(ao,nulldat) % Put the data (waveform) into the object

    start(ao) % Initialize the objects
    %wait(ao,1); % Wait 'till it's all over
    
    trigger(ao) % Acqire data
    wait(ao,1); % Wait 'till it's all over
    %ch=ao.Channel(t+1);
    delete(chan);
    
    
end

% Create an analog input object
ai = analoginput('nidaq','Dev1');
    