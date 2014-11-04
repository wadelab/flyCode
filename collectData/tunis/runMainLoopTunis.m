function finalData=runMainLoopTunis(patientInfo)% This version of the code sweeps over tf and sf space with no mask. It's
% just to generate the sftf sensitivity surfaces that we like so much...
% It replaces the original 'sweep' code and makes sure that everything is
% specified in the same units (in particular sf).
% ARW June 11 2014
%

startTime=tic;

DUMMYRUN=0;
dataDumpDir='c:\Users\c2d2\GDrive\Tunis\Data\';
errorDumpDir=[dataDumpDir,'ErrorMessage\'];

if (~DUMMYRUN)
    %Set    jheapcl;
    
    Screen('Preference', 'VisualDebuglevel', 0)% disables welcome and warning screens
    % HideCursor % Hides the mouse cursor
    
    
    % Get the calibration and compute the gamma table
    
    igt=fly_computeInverseGammaFromCalibFile('CalibrationData_200514.mat');
    dpy.gamma.inverse=igt;
end


datadir=pwd;
flyTV_startTime=now;

tic
dpy.res = [1680 1050]; % screen resolution
dpy.size = [.25 .15] % Meters
dpy.distance = [.6]; % Meters
dpy.frameRate=60;
dpy.activeScreen=1; % 1 is usually the onboard screen, 2 is the external
% dpy will eventually contain all the info about the display e.g. size,
% distance, refresh rate, spectra, gamma.
% For now if just has the gamma function (inverse) in it.


% Set up the EEG information
eegInfo.eegsamplerate = 256;
eegInfo.channels = 1:4;
eegInfo.nchannels = length(eegInfo.channels);
eegInfo.hwName='guadaq';
eegInfo.hwIndex=1;
eegInfo.DORECORDEEG=1;
eegInfo.notchFilterIndex=2;
eegInfo.bandFilterIndex=41;
% Set up the conditions. In the previous expt we varied TF and SF. In Tunis
% we will vary contrast and masking.

stim.tfList=[6; 8 ]'; % This is in Hz. And it is the same for all presentations
stim.sfList=[2 ; 2]'; % Cycles per degree probe, mask

stim.nTF=size(stim.tfList,1);
stim.nSF=size(stim.sfList,1);

stim.spatial.internalRotation = 0; % Does the grating rotate within the envelope?
stim.rotateMode = []; % rotation of mask grating (1= horizontal, 2= vertical, etc?)
stim.spatial.angle = [0 90]  ; % angle of gratings on screen
stim.temporal.duration=4; % how long to flicker for

% Loop over a set of contrast pair. All possible combinations of probe
% (0,14,28,56,70,80,99 % contrast) and mask(0,30%);
stim.probeCont=[0 0 2 4 8 16 32 69 69 ]/100;
stim.maskCont=[0 .3 .3 .3 .3 .3 .3 .3 0];
stim.nRepeats=10;
stim.nConds=size(stim.probeCont,2);

% Randomize the absolute rotation of the grating pairs. Relative
% orientations are still 90 degs.
stim.rotations=round(rand(stim.nRepeats,length(stim.probeCont))*360);

% Also randomize presentation order. 
origOrder=repmat([1:length(stim.probeCont)]',1,stim.nRepeats);
[stim.presentOrder,stim.shuffleIndex]=Shuffle(origOrder);
stim.presentOrder=stim.presentOrder';
stim.shuffleIndex=stim.shuffleIndex';

startTime=clock;
if (~DUMMYRUN)
    try
        d=human_runPlaid(dpy,stim,eegInfo);     % This function runs the grating and acquires data. If we did the screen opening outside the loop (or made it static?)
        % We might not have to
        % open the screen each
        % time around.
        finalData.d=d;
        finalData.patientInfo=patientInfo;
        
        finalData.triggerTime=d.TriggerTime; % Extract the data into a new struct because DAQ objects don't save nicely
        finalData.TimeStamps=d.TimeStamps;
        finalData.comment='HumanEEG';
        finalData.stim=stim;
        finaleData.eegInfo=eegInfo;
        finalData.now=now;
        finalData.stim=stim;
        finalData.data=d.Data;
        filename=fullfile(dataDumpDir,['EEG_',datestr(flyTV_startTime,30),'.mat'])
        save(filename,'finalData','d');
        data=d.Data;
        
    catch MAINERROR
        disp(MAINERROR.identifier);
        dataOut.message=MAINERROR;
        
        errorToFolder(MAINERROR,errorDumpDir) ;
        sca
        rethrow(MAINERROR)
    end
    
end % End check on dummy run

endTime=clock;
disp(etime(endTime,startTime));




end % End of function

%--------------------------------------------------------------------------------------------------
function errorToFolder(errorMessage,folder)
% Saves an error message to a folder
message.name='Error message';
message.now=now;
message.computer=computer;
message.version=version;
message.ver=ver;
message.passedError=errorMessage;
filename=fullfile(folder,['EEG_ERROR_',datestr(now,30),'.mat']);
save(filename,'message');

end

