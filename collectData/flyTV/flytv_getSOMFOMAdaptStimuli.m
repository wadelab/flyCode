function stim=flytv_getSOMFOMAdaptStimuli(exptSeq)
% Returns all possible stimli for this experiment in a structure. It's up
% to the calling function to work out what to do with them

stim(1).stimulusType='SOM'; 
stim(1).temporal.frequency=[4,4]; % This is in Hz. There are two frequencies for two grating components - in this case carrier and modulator. For flickering stimuli, this is the flicker rate. For drifting stimuli, this is the drift rate.
stim(1).spatial.frequency=[.04,.44]; % Cycles per degree modulator,carrier for a second order grating
stim(1).temporal.nTF=size(stim(1).temporal.frequency,1);
stim(1).spatial.nSF=size(stim(1).spatial.frequency,1);
stim(1).temporal.modulation.type='drift';
stim(1).temporal.modulation.stopStart=0; % 0 is constant, 1 is on/off, 2 is reversing
stim(1).temporal.modulation.frequency=[0 0]; % This is the alternation frequency for stimuli that drift
stim(1).spatial.angle = [0 0]  ; % angle of gratings on screen
stim(1).temporal.duration=30; % Adaptation period
stim(1).spatial.internalRotation = 0; % Does the grating rotate within the envelope?
stim(1).spatial.rotateMode = []; % rotation of mask grating (1= horizontal, 2= vertical, etc?)
stim(1).contrast=[40 50]; % Percent.
stim(1).spatial.phase=[0 0 ];
stim(1).rotateMode=0;


% That was the adaptor. Now the SOM probe. It's similar to the adaptor..
stim(2)=stim(1);
stim(2).temporal.modulation.stopStart=2; % 0 is constant, 1 is on/off, 2 is reversing

stim(2).temporal.duration=4; % Probe period
stim(1).temporal.modulation.frequency=[4 4]; % This is the reversal frequency for stimuli that drift

stim(3)=stim(1);
stim(3).stimulusType='FOM'; % First order modulation (includes contrast reversing gratings and plaids)
stim(3).spatial.frequency=[.04 .04]; % Cycles per degree Carrier,Modulator for a second order grating
stim(3).contrast=[80 0]; 
stim(4)=stim(2);
stim(4).stimulusType='FOM'; % First order modulation (includes contrast reversing gratings and plaids)
stim(3).contrast=[80 0]; 

% Finally some blanks..
stim(5)=stim(3);
stim(5).contrast=[0 0];
stim(6)=stim(4);
stim(6).contrast=[0 0];
