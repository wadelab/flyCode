function expt=getFlyExptStructtest(exptParams)
% exptStruct=getFlyExptStruct(exptParams)
% Get the parameters for all the experiments in a single structure
% exptParams()
% In general, each experiment is a different set of LEDs, frequencies,
% contrast ranges...
% Earlier versions of this code just handed in a single metadata element
% Now we already know the wavelengths, frequencies because they are set in
% the GUI
% The rest of the GUI output is held in exptParams.b


offVoltage=5.5;

exptIndex=1; % For now we just run the (fully randomized) CRF code.

% Have to set
% contRange, F1, F2, channel1, channel2, baseline1, baseline2,
nExpts=1; % Here we specify completely different sets of experiments. For example, one expt could have zero mask, the next could have 30% mask

% Stuff to do with the actual stimulus
% The 'expt' is now fully-randomized, no more probe-alone, then
% mask. So now there's only a single 'experiment'
thisExpt=1;

expt=exptParams;


%expt.nRepeats=repeats; % Option to repeat each experiment many times.
expt.chanBaselineArray=[offVoltage offVoltage]; % V. Can set this separately for ch1 and ch2 if required.
expt.baselineVoltage=3; % In real units, the baseline voltage of the average LED level. Remember that these boxes switch >off< at 5.5V!


expt.binDuration=1; % One second per bin
expt.binsPerTrial=10;  % Average this many bins together for each trial
expt.nPreBins=1; % Add on this many bins at the start of each trial to avoid onset transients.

switch expt.type % Which type of expt are we running
    case 1
        expt.nTrials=7; % Number of separate trial conditions. This will span the contrast range. We have reduced this slightly as it was not necessary to probe 10 separate cont levels.

        % First expt, first input, randomized contrast sequence
        expt.contRange(:,1)=[linspace(0,0.69,expt.nTrials),linspace(0,0.69,expt.nTrials)]; % Probe contrasts... the thing modulated at F1
        expt.contRange(:,2)=[zeros(1,expt.nTrials),ones(1,expt.nTrials)*0.3]; % This generates the mask contrasts.... F2

        expt.randSeq=randperm(expt.nTrials*2); % Randomize the sequence. First we generate a random permutation of the number between 1 and however many contrast steps we have. Then we re-index the contrast sequence using this vector
        expt.contRange(:,1)=expt.contRange(expt.randSeq,1); % Randomize the sequence.
        expt.contRange(:,2)=expt.contRange(expt.randSeq,2); % Randomize the sequence.
    case 2
    % This is a CRF that runs all the way to 100%
    % The analysis code needs to be changed to display this properly
        expt.nTrials=10; % Number of separate trial conditions. This will span the contrast range. We have reduced this slightly as it was not necessary to probe 10 separate cont levels.

        % First expt, first input, randomized contrast sequence
        expt.contRange(:,1)=[linspace(0,0.99,expt.nTrials)]; % Probe contrasts... the thing modulated at F1
        expt.contRange(:,2)=[zeros(1,expt.nTrials)]; % This generates the mask contrasts.... F2

        expt.randSeq=randperm(expt.nTrials); % Randomize the sequence. First we generate a random permutation of the number between 1 and however many contrast steps we have. Then we re-index the contrast sequence using this vector
        expt.contRange(:,1)=expt.contRange(expt.randSeq,1); % Randomize the sequence.
        expt.contRange(:,2)=expt.contRange(expt.randSeq,2); % Randomize the sequence.
end % End switch on expt type

expt.modType{1}='square'; % If this is >not< 'square' it is a sine wave (for now)
expt.modType{2}='square';

% Note - below we set a single frequency per expt. Freq sweeps
% could be implemented by making each of these a vector.


% Set the output channels. They are different color LEDs
% There are now two contrast ranges: each one is nTrials * nExpts;
expt.LEDChannels(:,1)=exptParams.F(1).LED(:); % This is now an array of zeros and ones with 1 meaning that the LED is used
expt.LEDChannels(:,2)=exptParams.F(2).LED(:); %

