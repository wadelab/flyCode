function [validFrequenciesHz]=flytv_computeValidFreqs(dpy)
% flytv_computeSampleLengthAndCycles(dpy,freq)
% For (currently) a single input frequency, computes the duration over
% which the analysis must be performed and the number of cycles expected in
% that duration.
%
% dpy must contain a field that says what the temporal frequency of the
% monitor is. 
%
% It returns the maximum duration of the same period (in seconds) and the
% integer number of cycles that will be contained within it.
% Eventually, this code will deal with two-input experiments and will
% return the bin sizes that correspond to each input pair.
%
% Example: if the frame rate is 100Hz, your available frame sets are
% 4,6,8,.... 100 which correspond to frequencies of 25, 16.66666, 12.5...
% 1Hz.
% 

monitorRateHz=dpy.frameRate; % Hz

% We sample at 1000Hz
sampleRateHz=1000; % This is fixed for now.

% We need to have an even, integer number of frames in a single stim cycle.
% The minumum number of frames that makes sense is 4 frames = 40ms.
% So the maximum stim tag frequency is 100/4 = 25Hz
% The minimum frequency that we want is probably 1Hz = 100 frames.

% We can compute the other valid stim tags as follows

validFrameSets=4:2:monitorRateHz;

validFrequenciesHz=1000./(validFrameSets*10)
 