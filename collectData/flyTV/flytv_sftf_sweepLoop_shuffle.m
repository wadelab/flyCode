close all;
clear all;
tfList=[1,2,4,8,16]; % This is in Hz.
sfList=[1 2 4 8 16]/1000; % We don't know what units this is in

nTF=length(tfList);
nSF=length(sfList);

ordered=1:(nTF*nSF); % This fully shuffles the order

r=Shuffle(ordered); % Shuffle all the possible presentation conditions 


for thisrun=1:5 % 5 repeats
    for temporalFrequencyIndex=1:nTF
        for spatialFrequencyIndex=1:nSF
            thisaction= r((temporalFrequencyIndex-1) * nTF + spatialFrequencyIndex)
            t=ceil(thisaction/ nSF);
            s=1+rem(thisaction, nTF); %  Should be 1+rem(thisAction-1,nTF)
            thisTF=tfList(t);
            thisSF=sfList(s);
            fprintf('\nRunning tf %d, sf %d',thisTF,thisSF);
            
            
            d=flytv_runGrating(thisTF,thisSF);     % This function runs the grating and acquires data. If we did the screen opening outside the loop (or made it static?)
            % We might not have to
            % open the screen each
            % time around.
            
            
            
            finalData.triggerTime=d.TriggerTime; % Extract the data into a new struct because DAQ objects don't save nicely
            finalData.Data=d.Data;
            finalData.TimeStamps=d.TimeStamps;
            finalData.Source=d.Source;
            finalData.EventName=d.EventName;
            finalData.comment='WT fly - data sweep';
            finalData.thisTF=thisTF;
            finalData.thisSF=thisSF;
            finalData.thisTFIndex=t;
            finalData.thisSFIndex=s;
            finalData.now=now;
            finalData.r=r;
            
            dataSet{temporalFrequencyIndex,spatialFrequencyIndex}=finalData; % Put the extracted data into an array tf x sf
            
            
            
        end % Next spatial frequency
    end % Next temporalFrequency
end    

save temp % This should change to a uniquywe filename than embeds the time and date using datestr and now






