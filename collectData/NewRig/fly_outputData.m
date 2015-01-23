function daqInfo=fly_outputData(daqInfo,dataSet)
% function daqInfo=fly_outputData(daqInfo,daqInfo.offVoltage)
% Outputs some data on the daq in foreground mode
% If only one value is provided it's copied cross all channels
if (length(dataSet(:))==1)
    
    f=repmat(dataSet,4,1);
    daqInfo.output.queueOutputData(f');
    daqInfo.output.prepare;
    daqInfo.output.startForeground;
else
    disp('Only able to set single values right now...');
end
