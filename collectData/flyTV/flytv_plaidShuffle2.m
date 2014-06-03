
close all;
clear all;
jheapcl;

Screen('Preference', 'VisualDebuglevel', 0)% disables welcome and warning screens
HideCursor % Hides the mouse cursor


% Get the calibration and compute the gamma table
igt=fly_computeInverseGammaFromCalibFile('CalibrationData_200514.mat')

datadir='C:\data\SSERG\data\';
flyTV_startTime=now;

dpy.gamma.inverse=igt;
dpy.res = [1920 1080]; % screen resoloution
dpy.size = [.53 .3] % Meters
dpy.distance = [.22]; % Meters

% dpy will eventually contain all the info about the display e.g. size,
% distance, refresh rate, spectra, gamma.
% For now if just has the gamma function (inverse) in it.

stim.temporal.frequency=[5 7]; % Hz
stim.spatial.frequency=[.1 .1]; % Cycles per degree

stim.spatial.internalRotation = 0; % Does the grating rotate within the envelope?
stim.rotateMode = []; % rotation of mask grating (1= horizontal, 2= vertical, etc?)

stim.spatial.angle = [0 0]  ; % angle of gratings on screen
stim.temporal.duration=11; % how long to flicker for

% Loop over a set of contrast pair. All possible combinations of probe
% (0,14,28,56,70,80,99 % contrast) and mask(0,40%);
probeCont=[0 14 28 56 70 80 99 0 14 28 56]/100;
maskCont =[0 0 0 0 0 0 0  40 40 40 40]/100;
nConds=length(probeCont);
condSeq=1:nConds;
shuffleSeq=Shuffle(condSeq);


for thisRun=1:5  % 5 repeats
    for thisCond=1:nConds
        stim.cont=[probeCont(shuffleSeq(thisCond)) maskCont(shuffleSeq(thisCond))];
        % Phase is the phase shift in degrees (0-360 etc.)applied to the sine grating:
        stim.spatial.phase=[0 0 ]; %[rand(1)*360 rand(1)*360];
        fprintf('\nRunning %d %d',stim.cont(1),stim.cont(2));
        
        
        
        d=flytv_runPlaid(dpy,stim);     % This function runs the grating and acquires data. If we did the screen opening outside the loop (or made it static?)
        % We might not have to
        % open the screen each
        % time around.
        
        
        
        finalData.triggerTime=d.TriggerTime; % Extract the data into a new struct because DAQ objects don't save nicely
        
        finalData.TimeStamps=d.TimeStamps;
        finalData.Source=d.Source;
        finalData.EventName=d.EventName;
        finalData.comment='Parallel_Grating_Wapr_D_7DPE';
        finalData.stim=stim;
        finalData.now=now;
     
        
        %filename=fullfile(datadir,[int2str(t),'_',int2str(s),'_',int2str(thisrun),'_',datestr(flyTV_startTime,30),'.mat'])
        %save(filename,'finalData');
        metaData{thisRun,thisCond}=finalData; % Put the extracted data into an array tf x sf x nrepeats
        data(thisRun,thisCond,:)=d.Data;
        
        
        
        
    end % Next contrast pair
end % Next repetition


filename=fullfile(datadir,['flyTV_',datestr(flyTV_startTime,30),'.mat'])
save(filename);






