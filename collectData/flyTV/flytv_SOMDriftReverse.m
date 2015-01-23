% This version of the code sweeps over tf and sf space with no mask. It's
% just to generate the sftf sensitivity surfaces that we like so much...
% It replaces the original 'sweep' code and makes sure that everything is
% specified in the same units (in particular sf).
% ARW June 11 2014
%
close all;
clear all;
startTime=clock;
DUMMYRUN=0;
commentFromHeader='L2_TNTe_1DPE_1 2:L2_TNTe_1DPE_2';

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


datadir='C:\data\SSERG\data\NewSweep\L2TNTe\SOM\';
flyTV_startTime=now;

dpy.res = [1920 1080]; % screen resoloution
dpy.size = [.53 .3] % Meters
dpy.distance = [.22]; % Meters
dpy.frameRate=144;

 if (strcmp(computer,'PCWIN64'))
    dpy.defaultScreen=1;
 else
     dpy.defaultScreen=0;
 end
 
% dpy will eventually contain all the info about the display e.g. size,
% distance, refresh rate, spectra, gamma.
% For now if just has the gamma function (inverse) insc it.

tfList=[4;4]'; % This is in Hz.

sfList=[.05,.05,.05,.05,.05,.05;.005,.22,.44,.88,1.76,3.25]'; % Cycles per degree Carrier,Modulator, 


nTF=size(tfList,1);
nSF=size(sfList,1);

ordered=1:(nTF*nSF); % This fully shuffles the order
shuffleSeq=Shuffle(ordered); % Shuffle all the possible presentation conditions


stim.spatial.internalRotation = 0; % Does the grating rotate within the envelope?
stim.rotateMode = []; % rotation of mask grating (1= horizontal, 2= vertical, etc?)

stim.spatial.angle = [0 0]  ; % angle of gratings on screen
stim.temporal.duration=11; % how long to flicker for

stim.temporal.modulation.type='drift';
stim.temporal.modulation.stopStart=2;

% Loop over a set of contrast pair. All possible combinations of probe
% (0,14,28,56,70,80,99 % contrast) and mask(0,30%);
probeCont=[40]/100;
maskCont =[50]/100;


nConds=length(ordered);

nRepeats=20;

for thisRun=1:nRepeats  % 5 repeats
    for thisCond=1:nConds
        
            if (strcmp(computer,'PCWIN64'))
                jheapcl; % For some reason this is required on PCWin64 arch
            end
    
        stim.cont=[probeCont(1) maskCont(1)];
        % Phase is the phase shift in degrees (0-360 etc.)applied to the sine gratiscng:
        stim.spatial.phase=[0 0 ]; %[rand(1)*360 rand(1)*360];
        stim.spatial.pOffset=rand(2,1)*360;

        fprintf('\nRunning cont1 %.2f cont2 %.2f',stim.cont(1),stim.cont(2));
        
        thisaction= shuffleSeq(thisCond);
        t=ceil(thisaction/ nSF);
        s=1+rem(thisaction, nSF); %  Should be 1+rem(thisAction-1,nTF)
        
        tt(thisRun,thisCond)=t;
        ss(thisRun,thisCond)=s;
        
        stim.spatial.frequency=sfList(s,:);
        stim.temporal.frequency=tfList(t,:);
        
        disp(thisRun)
        disp(thisCond)
        
        
        if (~DUMMYRUN)
            d=flytv_runSOMDriftReverse(dpy,stim);     % This function runs the grating and acquires data. If we did the screen opening outside the loop (or made it static?)
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
                
                singleRunDat=d.Data
                
                filename=fullfile(datadir,[int2str(t),'_',int2str(s),'_',int2str(thisRun),'_',datestr(flyTV_startTime,30),'.mat'])
                save(filename,'finalData','d','singleRunDat');
                metaData{thisRun,thisCond}=finalData; % Put the extracted data into an array tf x sf x nrepeats
                data(thisRun,thisCond,:,:)=d.Data;
            end
            
        end % End check on dummy run
        
        
    end % Next contrast pair
end % Next repetition
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



