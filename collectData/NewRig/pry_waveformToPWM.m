function outWave=pry_waveformToPWM(inputWave,inputCarrierFrequency, carrierFreq,samplesPerBin)
% outWave=pry_waveformToPWM(inputWave,inputCarrierFrequency, carrierFreq,samplesPerBin)
% Takes an input waveform inputWave (t x n) with n channels of t timepoints
% Returns a pulse width modulated version. The inputWave will be clipped 
% between 0 and 1 and a warning will be thrown if higher vals are detected.
% Smaller ranges between these limits are fine.
% The output carrier frequency and samplesPerBin (the resolution) are
% supplied. Samples per bin should be a divisor of carrier frequency.
% ARW 041013 - wrote it
% ARW 043113 - Fixed a major bug in the final line - < rather than > !
% 
% $LastChangedDate$
% $Rev$

% TODO: Parameter checking, flag quantization issues

nInputPoints=size(inputWave,1)

inputDurationSecs=nInputPoints/inputCarrierFrequency; % This doesn't have to be an integer.


% How many individual channels?
nChannels=size(inputWave,2);

nOutputPoints=carrierFreq*inputDurationSecs; % Total number of points in the output

nOutputBins=nOutputPoints/samplesPerBin; % This should be an integer. For now we will pad it out...
if (fix(nOutputBins)~=nOutputBins)
    error('Non-integer number of bins in output: check your input and output frequencies and bin size');
end 
 

% Resample the input waveform at a lower frequency (1/samplesPerBin) to get
% the PWM values
samplePoints=linspace(1,nInputPoints,nOutputBins);
resampledInput=interp1(inputWave,samplePoints'); % linear interpolation is  okay - we're subsampling

% Do clipping
if (sum(resampledInput>1))
    warning('Resampled input contains values >1: Clipping');
    resampledInput(resampledInput>1)=1;
end
if (sum(resampledInput<0))
    warning('Resampled input contains values <0: Clipping');
    resampledInput(resampledInput<0)=0;
end
 
% To create the PWM output we first generate a 'sawtooth' wave: Something
% that ramps between 0 and 1 smoothly and then drops back. To turn this
% into a PWM for each 'sawtooth' we can set everything below a particular
% value to '1' and everything else to '0'. 
outWave=mod(0:(nOutputPoints-1),samplesPerBin); % Sawtooth function. 
outWave=outWave/max(outWave(:));

outWave=repmat(outWave(:),1,nChannels); % Replicate this sawtooth function over all the channels.

compareWave=kron(resampledInput,ones(samplesPerBin,1)); % Uses the kronecker tensor produt to expand the waveform 
outWave=outWave<compareWave; %  The magic happens here :) 


