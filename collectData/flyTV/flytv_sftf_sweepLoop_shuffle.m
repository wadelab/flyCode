
close all;
clear all;
jheapcl;

Screen('Preference', 'VisualDebuglevel', 0)% disables welcome and warning screens
HideCursor % Hides the mouse cursor


% Get the calibration and compute the gamma table
igt=fly_computeInverseGammaFromCalibFile('CalibrationData_200514.mat')

datadir='C:\data\SSERG\data\';
flyTV_startTime=now;

tfList=[1,2,4.17,8.3,16.67,25]; % This is in Hz.
sfList=[1 2 4 8 16 32]/1000; % We don't know what units this is in

nTF=length(tfList);
nSF=length(sfList);

ordered=1:(nTF*nSF); % This fully shuffles the order

r=Shuffle(ordered); % Shuffle all the possible presentation conditions 

dpy.gamma.inverse=igt;

for thisrun=1:5 % 5 repeats
    jheapcl;
    for temporalFrequencyIndex=1:nTF
        for spatialFrequencyIndex=1:nSF
            thisaction= r((temporalFrequencyIndex-1) * nTF + spatialFrequencyIndex)
            t=ceil(thisaction/ nSF);
            s=1+rem(thisaction, nTF); %  Should be 1+rem(thisAction-1,nTF)
            thisTF=tfList(t);
            thisSF=sfList(s);
            fprintf('\nRunning tf %d, sf %d',thisTF,thisSF);
            
          
        
            d=flytv_runGrating(dpy,thisTF,thisSF);     % This function runs the grating and acquires data. If we did the screen opening outside the loop (or made it static?)
            % We might not have to
            % open the screen each
            % time around.
            
            
            
            finalData.triggerTime=d.TriggerTime; % Extract the data into a new struct because DAQ objects don't save nicely
            finalData.Data=d.Data;
            finalData.TimeStamps=d.TimeStamps;
            finalData.Source=d.Source;
            finalData.EventName=d.EventName;
            finalData.comment='wapr_O_calibrated_Extended_Sweep';
            finalData.thisTF=thisTF;
            finalData.thisSF=thisSF;
            finalData.thisTFIndex=t;
            finalData.thisSFIndex=s;
            finalData.now=now;
            finalData.r=r;
            
       
       
            filename=fullfile(datadir,[int2str(t),'_',int2str(s),'_',int2str(thisrun),'_',datestr(flyTV_startTime,30),'.mat'])
            save(filename,'finalData');
            dataSet{temporalFrequencyIndex,spatialFrequencyIndex,thisrun}=finalData; % Put the extracted data into an array tf x sf x nrepeats
                                                                                     
           
            
            
        end % Next spatial frequency
    end % Next temporalFrequency
end    

filename=fullfile(datadir,['flyTV_',datestr(flyTV_startTime,30),'.mat'])
save(filename);






