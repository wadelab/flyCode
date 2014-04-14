close all;
clear all;
tfList=[1,2,4,8,16]; % This is in Hz.
sfList=[1 2 4 8 16]/1000; % We don't know what units this is in

nTF=length(tfList);
nSF=length(sfList);

ordered=1:(nTF*nSF);

r=Shuffle(ordered); % Shuffle all the possible presentation conditions


%RandomTf = Shuffle(tfList)% shuffles tflist order
%RandomSf = Shuffle (sfList)% shuffles sflist order

for temporalFrequencyIndex=1:length(tfList)
    for spatialFrequencyIndex=1:length(sfList)
        thisaction= r(temporalFrequencyIndex,spatialFrequencyIndex)
        t=ceil(thisaction/ nSF);
        s=1+rem(thisaction , nTF);
            thisTF=tfList(t)
            thisSF=sfList(s)
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
            finalData.now=now;
            finalData.r=r;
            
            
            dataSet{temporalFrequencyIndex,spatialFrequencyIndex}=finalData; % Put the extracted data into an array tf x sf
            
            
            
    end % Next spatial frequency
end % Next temporalFrequency

save temp % This should change to a uniquywe filename than embeds the time and date using datestr and now




        

