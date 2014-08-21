 % This version of the code sweeps over tf and sf space with no mask. It's
% just to generate the sftf sensitivity surfaces that we like so much...
% It replaces the original 'sweep' code and makes sure that everything is
% specified in the same units (in particular sf).
% ARW June 11 2014
% ARW August 2015 - This version drifts a single bar across the screen at a particular repetition rate.

close all;
clear all;
startTime=tic;
DUMMYRUN=0;

if (~DUMMYRUN)
    %jheapcl;
    
    Screen('Preference', 'VisualDebuglevel', 0)% disables welcome and warning screens
    HideCursor % Hides the mouse cursor
    
    % Get the calibration and compute the gamma table
    
    igt=fly_computeInverseGammaFromCalibFile('CalibrationData_200514.mat')
    dpy.gamma.inverse=igt;
end


datadir='C:\data\SSERG\data\';
flyTV_startTime=now;


dpy.res = [1920 1080]; % screen resoloution
dpy.size = [.53 .3] % Meters
dpy.distance = [.22]; % Meters
dpy.frameRate=60;
% dpy will eventually contain all the info about the display e.g. size,
% distance, refresh rate, spectra, gamma.
% For now if just has the gamma function (inverse) insc it.

tfList=[5,5]'; % This is in Hz. Its the number of times a single bar is swept across the screen in 1s
sfList=[.05,.05;.44 .88]'; % Cycles per degree Modulator,Carrier,: Carrier is simple, modulator now is the width of the single bar in degs.

nTF=size(tfList,1);
nSF=size(sfList,1);

ordered=1:(nTF*nSF); % This fully shuffles the order
shuffleSeq=Shuffle(ordered); % Shuffle all the possible presentation conditions


stim.spatial.internalRotation = 0; % Does the grating rotate within the envelope?
stim.rotateMode = []; % rotation of mask grating (1= horizontal, 2= vertical, etc?)

stim.spatial.angle = [0 0]  ; % angle of gratings on screen
stim.temporal.duration=11; % how long to flicker for

stim.temporal.modulation.type='drift';
stim.temporal.modulation.stopStart=0;

% Loop over a set of contrast pair. All possible combinations of probe
% (0,14,28,56,70,80,99 % contrast) and mask(0,30%);
probeCont=[40]/100;
maskCont =[50]/100;

nConds=length(ordered);

nRepeats=1;

for thisRun=1:nRepeats  % 5 repeats
    for thisCond=1:nConds
        stim.cont=[probeCont(1) maskCont(1)];
        % Phase is the phase shift in degrees (0-360 etc.)applied to the sine gratiscng:
        stim.spatial.phase=[0 0 ]; %[rand(1)*360 rand(1)*360];
        stim.spatial.pOffset=rand(2,1)*360;
        
        fprintf('\nRunning %d %d',stim.cont(1),stim.cont(2));
        
        thisaction= shuffleSeq(thisCond);
        t=ceil(thisaction/ nSF)
        s=1+rem(thisaction, nSF) %  Should be 1+rem(thisAction-1,nTF)
        
        tt(thisRun,thisCond)=t;
        ss(thisRun,thisCond)=s;
        
        stim.spatial.frequency=sfList(s,:)
        stim.temporal.frequency=tfList(t,:)
        
        disp(thisRun)
        disp(thisCond)
        
        
        if (~DUMMYRUN)
            d=flytv_runPlaidSOM2FlickerFastTestDrift(dpy,stim);     % This function runs the grating and acquires data. If we did the screen opening outside the loop (or made it static?)
            % We might not have to
            % open the screen each
            % time around.
            
            if (isfield(d,'triggerTime'))
                
                finalData.triggerTime=d.TriggerTime; % Extracu    t the data into a new struct because DAQ objects don't save nicely
                finalData.TimeStamps=d.TimeStamps;
                finalData.Source=d.Source;
                finalData.EventName=d.EventName;
                
                finalData.comment='w-_7DPE_1_SO';
                finalData.stim=stim;
                finalData.now=now;
                finalData.nRepeats=nRepeats;
                finalData.thisRun=thisRun;
                finalData.thisCond=thisCond;
                finalData.shuffleSeq=shuffleSeq;
                finalData.tfList=tfList;
                finalData.sfList=sfList;
                finalData.data=d.data; % I'm nervous that d (because it's some sort of special object) doesn't get converted properly
                
                filename=fullfile(datadir,[int2str(t),'_',int2str(s),'_',int2str(thisRun),'_',datestr(flyTV_startTime,30),'.mat'])
                save(filename,'finalData','d');
                metaData{thisRun,thisCond}=finalData; % Put the extracted data into an array tf x sf x nrepeats
                data(thisRun,thisCond,:)=d.Data;
            end
            
        end % End check on dummy run
        
        
    end % Next contrast pair
end % Next repetition
totalSessionTime=toc;
return;
%
if ((~DUMMYRUN) && (isfield(d,'triggerTime')))
    filename=fullfile(datadir,['flyTV_SO_',datestr(flyTV_startTime,30),'.mat'])
    save(filename);
    
    
end




