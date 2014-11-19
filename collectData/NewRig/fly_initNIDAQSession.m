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
    catch AMPINITERROR
        disp('Could not initiate recording hardware');
        daqInfo.status=-1;
        daqInfo.message='Failed to initialize amp'; % Failed
        sca;
        
        rethrow(AMPINITERROR);
    end % End check on amp present
end % End try catch for initialization


    