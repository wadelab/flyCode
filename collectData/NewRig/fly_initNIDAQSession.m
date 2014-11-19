function daqInfo=fly_initNIDAQSession(daqInfo)
%  function daqInfo=fly_initNIDAQSession(daqInfo)
% Initializes the NIDAQ board using the new matlab session interface
% Note - we have to do this on new Win7 machines - XP no longer an option!
% daqInfo should be a structure containing useful information about the daq
% setup.
% Based on flytv_initializeDAQ.m
% The session (s) is returned as part of the daqInfo structure
% Note - we need simultaneous input and output: 4 output, 1 input.
% daqInfo.DAQ_PRESENT, daqInfo.hwName and daqInfo.devName must be defined.

try % This will fail, for example, on non-windows machines
    
    if (daqInfo.DAQ_PRESENT)
        
        disp('** Initializing amp ***');
        % Set up the input channel first
        daqInfo.s = daq.createSession(daqInfo.hwName);
        % daqInfo.hwName an daqInfo.devName are typically something like
        % 'ni' and 'Dev1'
        
        addAnalogInputChannel(daqInfo.s,daqInfo.devName,'ai0','Voltage');
        
        % Now set up the output channels - there are 4 of these...
        addAnalogOutputChannel(daqInfo.s,daqInfo.devName,0:3,'Voltage');
        % Note that (we hope) everything is triggered and synchronized
        % together. Stuff like duration and number of scans are read-only :
        % determined by the output rate and the number of data points
        % stacked up in the output buffer.
        % http://uk.mathworks.com/help/daq/acquire-data-and-generate-signals-simultaneously.html
        
        % Unlike the flytv code where we need to run the daq in the
        % background (to run image display in the FG) we can trigger
        % everything here in the FG: Hopefully the DAQ can keep up...
        
        
        
        daqInfo.status=1;
        daqInfo.message='Amp initialized'; % Okay
    else
        daqInfo.status=-1;
        daqInfo.message='NO DAQ PRESENT ACCORDING TO daqInfo';
        % End check on daq presence
    end
catch AMPINITERROR
    disp('Could not initiate recording hardware');
    daqInfo.status=-1;
    daqInfo.message='Failed to initialize amp'; % Failed
    sca;
    
    rethrow(AMPINITERROR);
    
end % End try catch for initialization

%% Stuff below has to be incorporated into this function as well...
 %% Here we set up the trials and run them. We will store data on a
%         % per-trial basis and chop it up later.
%         
%         % Data will be acquired from hardware channels 0,1 and 5. These are
%         % the two input
%         % electrodes and the photodiode.
%         channelList=[0 1 5]; % List of hardware (NIDAQ - reference type) input channels. It is very important that these are in the right order!!!!
%         
%         %% Set up the input system - we can do this just once per expt: Data will
%         % come into the same buffer each time and we can extract it after
%         % each trialfor thisChannelToInit=1:length(channelList)
%         
%         for thisChannelToInit=1:length(channelList)
%             
%             addchannel(ai, channelList(thisChannelToInit));
%             % Configure the analog input
%             set(ai.Channel(thisChannelToInit),'InputRange',[-10 10]);
%             set(ai.Channel(1),'SensorRange',[-10,10]);
%             set(ai.Channel(1),'UnitsRange',[-10 10]);
%             set(ai,'InputType',digitizerAmpMode);
%         end
%         
%         
%         
%         ai.SampleRate = digitizerSampleRate; % Rate in samples / second
%         ai.SamplesPerTrigger = digitizerSampleRate*totalTrialDuration;
%         % Make it a manual trigger and link it to the output trigger
%         
%         %% Set up the output channels. There are two for now - more perhaps later
%         %when we do silent substitution
%         % However, there's no reason not to initialize all 4
%         chans = addchannel(ao,0:(nOutChans-1));
%         set(ao,'SampleRate',outputPWMCarrierRate);
%         ActualOutputRate = get(ao,'SampleRate');
%         set([ai ao],'TriggerType','Manual')
%         set(ai,'ManualTriggerHwOn','Trigger')
%         
%     else
%         ActualOutputRate=digitizerSampleRate;
% end
%     
    
