function expt=getFlyExptStructAdapt(exptIndex)
% exptStruct=getFlyExptStructAdapt(exptset)
% Get the parameters for all the experiments in a single structure
% exptParams()
% In general, each experiment is a different set of LEDs, frequencies,
% contrast ranges...
%
% You can specify entirely different sets of experiments using exptSet
% expt is a cell array
% ARW 070612: Added random sequencing and multiple repeats.
% ARW and JR 011612: Modified to generate an adaptation experiment: adapt
% period followed by some probe periods.


offVoltage=5.5;


switch exptIndex
    case {1,2,3} % We have 6x2 individual experiment types. 6 probe contrasts, 2 adaptation levels.
        
        
        % Have to set
        % contRange, F1, F2, channel1, channel2, baseline1, baseline2,
        nExpts=1; % Here we specify completely different sets of experiments. For example, one expt could have zero mask, the next could have 30% mask
        repeats=1;
        
        % Stuff to do with the actual stimulus
            expt.nRepeats=repeats; % Option to repeat each experiment many times.
            expt.chanBaselineArray=[offVoltage,offVoltage,offVoltage,offVoltage]; % V. Can set this separately for ch1 and ch2 if required.
            expt.baselineVoltage(1)=4;
            
            expt.chanBaselineArray(exptIndex)=expt.baselineVoltage(1);
            
            expt.binDuration=1; % One second per bin
            expt.binsPerTrial=2;  % Average this many bins together for each trial
            expt.nPreBins=1; % Add on this many bins at the start of each trial to avoid onset transients.
            expt.nProbeConds=6; % Number of separate trial conditions. This will span the contrast range.
            expt.nAdaptConds=2;
            expt.nTrials=expt.nAdaptConds*expt.nProbeConds; % Total number of trials in an experiment.
            expt.probeTimesAfterAdapt=[0 10 20];
            expt.adaptDuration=20;

       % First expt, first input, randomized contrast sequence
        expt.probeContRange=[0 5 10 20 40 80]/100; % This should be a log-spaced value but for now keep it simple. 1 is 100% contrast. 0 is no modulation
        expt.adaptContRange=[0 80]/100;
        
        probeSeq=repmat(expt.probeContRange,1,expt.nAdaptConds);
        adaptContSeq=kron(expt.adaptContRange,ones(1,length(expt.probeContRange)));
        
        
        
        expt.randSeq=randperm(length(probeSeq)); % Randomize the sequence. First we generate a random permutation of the number between 1 and however many contrast steps we have. Then we re-index the contrast sequence using this vector
        expt.probeContSeq=probeSeq(expt.randSeq); % Randomize the sequence. 
        expt.adaptContSeq=adaptContSeq(expt.randSeq);
        
    
      
        
        expt.modType{1}='square'; % If this is >not< 'square' it is a sine wave (for now)
        
        % Note - below we set a single frequency per expt. Freq sweeps
        % could be implemented by making each of these a vector.
        
        expt.F(1)=6; % Hz. The modulation frequency of the first input, first expt
        
        
     
    otherwise
        
        error('Bad experiment number');
end

% Set the output channels. They are different color LEDs
        % There are now two contrast ranges: each one is nTrials * nExpts;
        expt.LEDChannel(1)=exptIndex-1; % This is the channel of the LED output. I think there are 3 or 4 available with different colors.
        expt.LEDChannel(2)=exptIndex-1; %
        expt.LEDChannel(1)=exptIndex-1; %
        expt.LEDChannel(2)=exptIndex-1; %
   % Here, set more stuff that we want to be constant across expts
        exptSet.nChannels=size(unique(expt.LEDChannel));
        
    