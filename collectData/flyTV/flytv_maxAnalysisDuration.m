function totalAnalysisDurationSecs = flytv_maxAnalysisDuration(dpy,freq,maxAcquisitionLengthSecs)
% function totalSampleDuration = flytv_maxAnalysisDuration(dpy,freq,maxAcquisitionLengthSecs)
%
%For a given frequency (that is validfor the current frame rate: see
%flytv_computeValidFrequencies) you want to know how long your analysis
%window is. The critical thing is to have an integer number of frequencies
%in there....

monitorRateHz=dpy.frameRate; % Hz

% We sample at 1000Hz
sampleRateHz=1000; % This is fixed for now.

% We need to have an even, integer number of frames in a single stim cycle.
% The minumum number of frames that makes sense is 4 frames = 40ms.
% So the maximum stim tag frequency is 100/4 = 25Hz
% The minimum frequency that we want is probably 1Hz = 100 frames.

% Check to make sure that this frequency is allowed...
[validFrequencies]=flytv_computeValidFrequencies(dpy);
if (~ismember(freq,validFrequencies))
    error('Invalid input frequency for this monitor - must be even number of frames');
end


frameDurationms=1000/monitorRateHz;

cycleDurationms=(monitorRateHz/freq)*frameDurationms;



maxNumberCycles=fix(maxAcquisitionLengthSecs*1000./cycleDurationms);
% TotalDuration can then be computed
totalAnalysisDurationSecs = maxNumberCycles*cycleDurationms/1000;
