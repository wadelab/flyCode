% This version of the code sweeps over tf and sf space with no mask. It's
% just to generate the sftf sensitivity surfaces that we like so much...
% It replaces the original 'sweep' code and makes sure that everything is
% specified in the same units (in particular sf).
% ARW June 11 2014
% This version: Major updates:
% TRY, CATCH stuff added. Initializing Screen now outside main loop (so
% only happens once).
% See Tunis code for more examples.

close all;
clear all;
startTime=clock;
DUMMYRUN=0;
commentFromHeader='w-_1DPE_10_SOC_4Hz';

if (~DUMMYRUN)
    
    if (strcmp(computer,'PCWIN64'))
        jheapcl; % For some reason this is required on PCWin64 arch
    end
    
    Screen('Preference', 'VisualDebuglevel', 0)% disables welcome and warning screens
    HideCursor % Hides the mouse cursor
    
    % Get the calibration and compute the gamma table
    igt=fly_computeInverseGammaFromCalibFile('CalibrationData_200514.mat')
    dpy.gamma.inverse=igt;
end


datadir='C:\data\SSERG\data\SOC_Drift\1DPEw-\2Hz\';
flyTV_startTime=now;

dpy.res = [1920 1080]; % screen resoloution
dpy.size = [.53 .3] % Meters
dpy.distance = [.22]; % Meters
dpy.frameRate=60;
dpy.VisualDebugLevel=1;
dpy.SkipSyncTests=1;
dpy.SuppressAllWarnings=1;




if (strcmp(computer,'PCWIN64'))
    dpy.defaultScreen=1;
else
    dpy.defaultScreen=0;
end

% dpy will eventually contain all the info about the display e.g. size,
% distance, refresh rate, spectra, gamma.
% For now if just has the gamma function (inverse) insc it.

% Stim is now a struct array. It contains information for multiple stimuli
% which can be chained together...
stim(1).temporal.tf=[4,4]; % This is in Hz. There are t frequencies for two grating components - in this case carrier and modulator. For flickering stimuli, this is the flicker rate. For drifting stimuli, this is the drift rate.
stim(1).spatial.sf=[.44,.04]; % Cycles per degree Carrier,Modulator,
stim(1).temporal.nTF=size(stim(1).temporal.tf,1);
stim(1).spatial.nSF=size(stim(1).spatial.sf,1);
stim(1).temporal.modulation.type='drift';
stim(1).temporal.modulation.stopStart=0; % 0 is constant, 1 is on/off, 2 is reversing
stim(1).spatial.angle = [0 0]  ; % angle of gratings on screen
stim(1).temporal.duration=30; % Adaptation period
stim(1).spatial.internalRotation = 0; % Does the grating rotate within the envelope?
stim(1).spatial.rotateMode = []; % rotation of mask grating (1= horizontal, 2= vertical, etc?)
stim(1).contrast=[40 50]; % Percent.
stim(1).spatial.phase=[0 0 ];
% That was the adaptor. Now the probe. It's similar to the adaptor..
stim(2)=stim(1);
stim(2).temporal.modulation.stopStart=2; % 0 is constant, 1 is on/off, 2 is reversing
stim(2).temporal.duration=4; % Probe period

% Note: the order of the stimulus (1st or 2nd order motion) is set by the

% Set up the EEG information
eegInfo.eegsamplerate = 1000;
eegInfo.channels = 1;
eegInfo.nchannels = length(eegInfo.channels);
eegInfo.hwName='ni';
eegInfo.hwIndex=3;
eegInfo.DORECORDEEG=1;


expt.stimType=[1 2 1 2;1 1 2 2]; % This defines the order of the adaptor and probe. 1 means 1st order motion, 2 means 2nd order motion
expt.nConds=size(expt.stimType,2); % How many pairs of conditions do we run? In this case it's 2x2 so 4...
% Later we will randomize these but for
% now we don't

expt.nRepeats=20; % How many times do we repeat the entire sequence? There is now an expt structure that contains information about the entire experiment

% 
expt.stim=stim;
expt.eegInfo=eegInfo;


% Initialize the screen. This now happens in a separate function
[dpy]=flytv_initializeScreen(dpy);

if(dpy.status~=1)
    error('Screen not initialized');
end


if (strcmp(computer,'PCWIN64'))
    jheapcl; % For some reason this is required on PCWin64 arch
end

if (~DUMMYRUN)
    d=flytv_runSOMAdapt(dpy,expt);     % This function runs the grating and acquires data. If we did the screen opening outside the loop (or made it static?)
    % We might not have to
    % open the screen each
    % time around.
    
    if (isprop(d,'TriggerTime'))
        
        finalData.triggerTime=d.TriggerTime; % Extracu    t the data into a new struct because DAQ objects don't save nicely
        finalData.TimeStamps=d.TimeStamps;
        finalData.Source=d.Source;
        finalData.EventName=d.EventName;
        
        finalData.comment=commentFromHeader;
        finalData.stim=stim;
        finalData.now=now;
        finalData.nRepeats=nRepeats;
        finalData.thisRun=thisRun;
        finalData.thisCond=thisCond;
        finalData.shuffleSeq=shuffleSeq;
        finalData.tfList=tfList;
        finalData.sfList=sfList;
        finalData.data=d.Data; % I'm nervous that d (because it's some sort of special object) doesn't get converted properly
        
        filename=fullfile(datadir,[int2str(t),'_',int2str(s),'_',int2str(thisRun),'_',datestr(flyTV_startTime,30),'.mat'])
        save(filename,'finalData','d');
        metaData{thisRun,thisCond}=finalData; % Put the extracted data into an array tf x sf x nrepeats
        data(thisRun,thisCond,:)=d.Data;
    end
    
end % End check on dummy run


totalSessionTime=toc;

%
if ((~DUMMYRUN) && (isprop(d,'TriggerTime')))
    
    filename=fullfile(datadir,['flyTV_SOM_',datestr(flyTV_startTime,30),'.mat']);
    fprintf('\nSaving all data in %s',filename);
    save(filename);
    
    
end
disp('Total elapsed time (s) for this experiment:');
etime(clock,startTime)
return



