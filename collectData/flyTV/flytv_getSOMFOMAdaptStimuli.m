function stim=flytv_getSOMFOMAdaptStimuli(exptSeq)
% Returns all possible stimli for this experiment in a structure. It's up
% to the calling function to work out what to do with them

stim(1).stimulusType='SOM'; 
stim(1).temporal.frequency=[6 0]; % This is in Hz. There are two frequencies for two grating components - in this case carrier and modulator. For flickering stimuli, this is the flicker rate. For drifting stimuli, this is the drift rate.
stim(1).spatial.frequency=[.04,.44]; % Cycles per degree modulator,carrier for a second order grating
stim(1).temporal.nTF=size(stim(1).temporal.frequency,1);
stim(1).spatial.nSF=size(stim(1).spatial.frequency,1);
stim(1).temporal.modulation.type='drift';
stim(1).temporal.modulation.stopStart=0; % 0 is constant, 1 is on/off, 2 is reversing
stim(1).temporal.modulation.frequency=[0 0]; % This is the alternation frequency for stimuli that drift
stim(1).temporal.modulation.direction=[-1 -1]; % This is the direction in which the grating moves. 1 means a leftward drift, -1 means rightward

stim(1).spatial.angle = [0 0]  ; % angle of gratings on screen
stim(1).temporal.duration=30; % Adaptation period
stim(1).spatial.internalRotation = 0; % Does the grating rotate within the envelope?
stim(1).spatial.rotateMode = []; % rotation of mask grating (1= horizontal, 2= vertical, etc?)
stim(1).contrast=[40 50]; % Percent.
stim(1).spatial.phase=[0 0 ];
stim(1).rotateMode=0;

% That was the adaptor. Now the SOM probe. It's similar to the adapter..
stim(2)=stim(1);
stim(2).temporal.modulation.stopStart=2; % 0 is constant, 1 is on/off, 2 is reversing
stim(2).temporal.duration=4; % Probe period
stim(2).temporal.modulation.frequency=[4 4]; % This is the reversal frequency for stimuli that drift

stim(3)=stim(1);  % This is first order constant drift adaptor
stim(3).temporal.frequency=[12 0]; % This is in Hz. There are two frequencies for two grating components - in this case carrier and modulator. For flickering stimuli, this is the flicker rate. For drifting stimuli, this is the drift rate.
stim(3).stimulusType='FOM'; % First order modulation (includes contrast reversing gratings and plaids)
stim(3).spatial.frequency=[.04 .04]; % Cycles per degree Carrier,Modulator for a second order grating
stim(3).contrast=[80 0]; 

stim(4)=stim(2); % First order probe
stim(4).temporal.frequency=[6 6]; % This is in Hz. There are two frequencies for two grating components - in this case carrier and modulator. For flickering stimuli, this is the flicker rate. For drifting stimuli, this is the drift rate.
stim(4).stimulusType='FOM'; % First order modulation (includes contrast reversing gratings and plaids)
stim(4).contrast=[80 0]; 
stim(4).spatial.frequency=[.04 .04]; % Cycles per degree Carrier,Modulator for a second order grating

% Finally some blanks..
stim(5)=stim(3);
stim(5).contrast=[0 0];
stim(6)=stim(4);
stim(6).contrast=[0 0];

% Here we have first and second order motion adaptors with reversal. This
% is to test timing and make sure that the reversal itself generates a nice
% response
stim(7)=stim(2); % Second order reverse adapt
stim(7).temporal.duration=30; % Probe period

stim(8)=stim(4); % First order reverse adapt
stim(8).temporal.duration=30; % Probe period

stim(9)=stim(2); % Second order reverse probe 2Hz
% Change the alternation frequency to be a little lower....
stim(9).temporal.modulation.frequency=[2 2]; % This is the reversal frequency for stimuli that drift

stim(10)=stim(4); % First order probe again - 2Hz reversal
stim(10).temporal.modulation.frequency=[2 2]; % This is the reversal frequency for stimuli that drift

stim(11)=stim(2); % Second order reverse probe 6Hz
% Change the alternation frequency to be a little lower....
stim(11).temporal.modulation.frequency=[6 6]; % This is the reversal frequency for stimuli that drift
stim(11).label='2ndOrder6HzProbe';

stim(12)=stim(4); % First order reverse probe again - 6Hz reversal
stim(12).temporal.modulation.frequency=[6 6]; % This is the reversal frequency for stimuli that drift
stim(12).label='1storder6HzProbe';

stim(13)=stim(3); % First order adaptor - change direction
stim(13).temporal.modulation.direction=[1 1]; % This is the direction in which the grating moves. 1 means a leftward drift, -1 means rightward
stim(13).label='LeftwardAdapt';

stim(14)=stim(4); % First order reverse probe again - 8Hz reversal
stim(14).temporal.modulation.frequency=[8 8]; % This is the reversal frequency for stimuli that drift
stim(14).label='1stOrder8HzProbe';

stim(15)=stim(4); % First order reverse probe again - 6Hz reversal
stim(15).temporal.modulation.frequency=[4 4]; % This is the reversal frequency for stimuli that drift
stim(15).label='1stOrder4HzProbe';

stim(16)=stim(5);
stim(16).temporal.duration=1;
stim(16).label='Blank 1second';
