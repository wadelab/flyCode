% This version of the code sweeps over tf and contrast space with no mask. It's
% just to generate the comtrast vs tf sensitivity surfaces that we like so much...
% It replaces the original 'sweep' code and makes sure that everything is
% specified in the same units (in particular tf).
% ARW June 11 2014
% ARW Feb 2016: This version sweeps over contrast and TF (not SF)
close all;
clear all;
jheapcl;
startTime=tic;
DUMMYRUN=0;

if (~DUMMYRUN)
    jheapcl;
    
    Screen('Preference', 'VisualDebuglevel', 0)% disables welcome and warning screens
    HideCursor % Hides the mouse cursor
    
    
    % Get the calibration and compute the gamma table
    
    igt=fly_computeInverseGammaFromCalibFile('CalibrationData_200514.mat')
    dpy.gamma.inverse=igt;
end


datadir='C:\data\SSERG\data\Marc\W-_1d';
flyTV_startTime=now;


dpy.res = [1920 1080]; % screen resoloution
dpy.size = [.53 .3] % Meters
dpy.distance = [.22]; % Meters
dpy.frameRate=144;
% dpy will eventually contain all the info about the display e.g. size,
% distance, refresh rate, spectra, gamma.
% For now if just has the gamma function (inverse) in it.

tfList=[1,2,4,6,8,12,18,36;1,2,4,6,8,12,18,36]'; % This is in Hz.
sfList=[.056]'; % Cycles per degree - in this version of the code nothing changes here,.
contList=[1 2 4 8 16 32 64 99;0 0 0 0 0 0 0 0]'/100;  % Contrasts to probe
nTF=size(tfList,1);
nSF=size(sfList,1);
nCont=size(contList,1);

ordered=1:(nTF*nCont); % This fully shuffles the order
shuffleSeq=Shuffle(ordered); % Shuffle all the possible presentation conditions


stim.spatial.internalRotation = 0; % Does the grating rotate within the envelope?
stim.rotateMode = []; % rotation of mask grating (1= horizontal, 2= vertical, etc?)

stim.spatial.angle = [0 0]  ; % angle of gratings on screen
stim.temporal.duration=11; % how long to flicker for

% In principle we can have both mask and probe here. For now though we set
% the mask to zero
probeCont=[99]/100;
maskCont =[0];

nConds=length(ordered);

nRepeats=3;

for thisRun=1:nRepeats  % 5 repeats
    for thisCond=1:nConds
        stim.spatial.frequency=[sfList(1), sfList(1)]; % Set the same spatial freq for both components
        % Phase is the phase shift in degrees (0-360 etc.)applied to the sine grating:
        stim.spatial.phase=[0 0 ]; %[rand(1)*360 rand(1)*360];
        stim.spatial.pOffset=rand(2,1)*360;
        
  
        thisaction= shuffleSeq(thisCond);
        tIndex=ceil(thisaction/ nCont) % Index into the list of temporal frequencies
        cIndex=1+rem(thisaction, nCont) %  Should be 1+rem(thisAction-1,nTF)  - index into the list of contrasts
        
        thisTemp(thisRun,thisCond)=tIndex;
        thisCont(thisRun,thisCond)=cIndex;
        
        stim.temporal.frequency=tfList(tIndex,:)
        stim.cont=contList(cIndex,:);
        disp(thisRun)
        disp(thisCond)
              fprintf('\nRunning %d %d',stim.cont(1),stim.cont(2));
        
        
        if (~DUMMYRUN)
            d=flytv_runPlaid(dpy,stim);     % This function runs the grating and acquires data. If we did the screen opening outside the loop (or made it static?)
            % We might not have to
            % open the screen each
            % time around.
            
            finalData.triggerTime=d.TriggerTime; % Extract the data into a new struct because DAQ objects don't save nicely
            
            finalData.TimeStamps=d.TimeStamps;
            finalData.Source=d.Source;
            finalData.EventName=d.EventName;
            finalData.flyName{1}='dummy1';
            finalData.flyName{2}='dummy2';
            
            
            finalData.comment='a fly '; % Here : the first data channel ('ai0') is the bottom fly.
            finalData.stim=stim;
            finalData.now=now;
            finalData.nRepeats=nRepeats;
            finalData.thisRun=thisRun;
            finalData.thisCond=thisCond;
            finalData.shuffleSeq=shuffleSeq;
            finalData.tfList=tfList;
            finalData.sfList=sfList;
            
            %singleRunDat=d.Data;
            filename=fullfile(datadir,[int2str(tIndex),'_',int2str(cIndex),'_',int2str(thisRun),'_',datestr(flyTV_startTime,30),'.mat'])
            %save(filename,'finalData','d','singleRunDat');
            metaData{thisRun,thisCond}=finalData; % Put the extracted data into an array tf x sf x nrepeats
            data(thisRun,thisCond,:,:)=d.Data;
            
            
        end % End check on dummy run
        
        jheapcl;
    end % Next contrast pair
end % Next repetition
totalSessionTime=toc;
if (~DUMMYRUN)
    filename=fullfile(datadir,['flyTV_CRF',datestr(flyTV_startTime,30),'.mat'])
    save(filename);
    
    
end




