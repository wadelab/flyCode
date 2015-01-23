function eegInfo=flytv_initializeDAQ(eegInfo)
% function eegInfo=flytv_initializeDAQ(eegInfo)
% ARW 103114
%Initialise the daq if the appropriate flag is set in eegInfo
if (eegInfo.DAQ_PRESENT)
    try
        disp('** Initializing amp ***');
        
        eegInfo.s = daq.createSession(eegInfo.hwName);
        eegInfo.s.DurationInSeconds = eegInfo.bufferSizeSeconds;
        addAnalogInputChannel(eegInfo.s,'Dev3','ai0','Voltage');
        addAnalogInputChannel(eegInfo.s,'Dev3','ai1','Voltage');

        eegInfo.s.NumberOfScans = eegInfo.s.DurationInSeconds*1000;
        eegInfo.s.NotifyWhenDataAvailableExceeds = eegInfo.s.NumberOfScans;
        
        eegInfo.listenerHandle = addlistener(eegInfo.s,'DataAvailable', @flytv_dumpData);
        eegInfo.status=1;
        eegInfo.message='Amp initialized'; % Okay
    catch AMPINITERROR
        disp('Could not initiate recording hardware');
        eegInfo.status=-1;
        eegInfo.message='Failed to initialize amp'; % Failed
        sca;
        
        rethrow(AMPINITERROR);
    end % End try catch for initialization
end % End check on amp present

