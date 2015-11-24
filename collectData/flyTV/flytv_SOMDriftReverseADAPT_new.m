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
tic
DUMMYRUN=0;
commentFromHeader='Testingwapr';


if (strcmp(computer,'PCWIN64'))
    jheapcl; % For some reason this is required on PCWin64 arch
end

Screen('Preference', 'VisualDebuglevel', 0)% disables welcome and warning screens
HideCursor % Hides the mouse cursor

% Get the calibration and compute the gamma table
igt=fly_computeInverseGammaFromCalibFile('CalibrationData_200514.mat');
dpy.gamma.inverse=igt;


datadir='C:\data\SSERG\data\Adaptation_Nov15\';
flyTV_startTime=now;

% Set up display specific parameters. Really these should be in a proper
% calibration file a la exptTools
dpy.res = [1920 1080]; % screen resolution
dpy.size = [.53 .3]; % Meters
dpy.distance = [.22]; % Meters
dpy.frameRate=144;
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
% which can be chained together.. Here we define all the possible stimuli
% in this experiment: 
stim=flytv_getSOMFOMAdaptStimuli(dpy);

% These stimuli are, in order:
% 1: SOM ADAPT
% 2: SOM PROBE
% 3: FOM ADAPT
% 4: FOM PROBE
% 5: BLANK ADAPT (Zero contrast, same length)  
% 6: BLANK PROBE (Zero contrast, same length)

% Our job below is to set up an expt so that we look at all combinations od
% these.


% Set up the EEG information
eegInfo.eegsamplerate = 1000;
eegInfo.channels = 1;
eegInfo.nchannels = length(eegInfo.channels);
eegInfo.hwName='ni';
eegInfo.hwIndex=3;
eegInfo.DORECORDEEG=1;
eegInfo.DAQ_PRESENT=1;
eegInfo.bufferSizeSeconds=31;

expt.stimType=[ 5  3   3  13;...
               14  14  6  14  ]; % This defines the order of the adaptor and probe. 1 means 1st order motion, 2 means 2nd order motion
expt.nConds=size(expt.stimType,2); % How many pairs of conditions do we run? In this case it's 2x2 so 4...
% Later we will randomize these but for
% now we don't

expt.nRepeats=30; % How many times do we repeat the entire sequence? There is now an expt structure that contains information about the entire experiment

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
    try
        dataOut=flytv_runMotionAdapt(dpy,expt);     % This function runs the grating and acquires data. If we did the screen opening outside the loop (or made it static?)
        % This returns a big block of data containing everything from all the runs
        filename=fullfile(datadir,['allData_',datestr(flyTV_startTime,30),'.mat']);
        
        % Save all the data in an appropriate directory.
        fprintf('\nSaving %s\n',filename);
       % save(fullfile(['allDataLocal_',datestr(flyTV_startTime,30),'.mat'])); % Save everything in local dir in case of crash
        save(filename,'dataOut','expt','stim','eegInfo','dpy');
        
    catch MAINLOOPERROR
        sca
        save('ErrorState');
        rethrow(MAINLOOPERROR);
    end
    
end % End check on dummy run
sca

toc

return



