function badBinFlags=ss_noiseCheck(inputData,exptStruct,rejectParams)
% function badBinFlags=ss_noiseCheck(inputData,exptStruct,[rejectParams])
% Flags bad bins in the input dataset
% The input data should have the following dimensions
% samples x bins x contrastConditions x exptConditions x repetitions
% All of these dimensions must be present even if they are singleton.
% exptStruct must contain all the usual information about the SS experiment
% (in particular, F1 and F2).
% Returns a matrix which is bins x contrast x exptconds x reps
% Each element is 1 (for a good bin) and 0 (for a rejected bin).
% rejectParams (optional) can contain criteria for rejection such as a df
% limit


% TD continued...
% Let's take a look at some statistics: 
% First, compute the non-signal bands
if (nargin <3)
    rejectParams.sd=1.5;
    rejectParams.maxFreq=100;
end


inputFreqs=exptStruct.F;
  % Compute sums and diffs up to 2F im terms
  signalTerms=[inputFreqs(:);2*inputFreqs(:);sum(inputFreqs(:));sum(2*inputFreqs(:));abs(inputFreqs(1)-inputFreqs(2));abs(2*inputFreqs(1)-inputFreqs(2));abs(2*(inputFreqs(1)-inputFreqs(2)));inputFreqs(1)+2*inputFreqs(2);2*inputFreqs(1)+inputFreqs(2)];
  
  noiseTerms=setdiff([1:rejectParams.maxFreq],signalTerms);
 
  % Each bin contains about 1000 samples. We will start by FFTing each bin
  % and computing the abs fourier responses at each of the noise terms.
  fData=fft(inputData);
  RMS_noiseTermAmps=sqrt(sum(abs(fData(noiseTerms+1,:,:,:,:)).^2)); % Noise per bin
  
  
  % Reject anything where the noise terms are more than rejectParams.sd
  % outside the population distribution
  sd=std(RMS_noiseTermAmps(:));
  badBinFlags=(RMS_noiseTermAmps>rejectParams.sd*sd);
  
  