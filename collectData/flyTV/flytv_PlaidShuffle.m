close all
close all;
clear all;
clear mex;

%datadir='C:\data\SSERG\data\';
%flyTV_startTime=now;

tfList=[1,2,4,8,16]; % This is in Hz.
sfList=[1 2 4 8 16]/1000; % We don't know what units this is in

nTF=length(tfList);
nSF=length(sfList);

ordered=1:(nTF*nSF); % This fully shuffles the order

r=Shuffle(ordered); % Shuffle all the possible presentation conditions 


for thisrun=1:1 % 5 repeats
    for temporalFrequencyIndex=1:nTF
        for spatialFrequencyIndex=1:nSF
            thisAction= r((temporalFrequencyIndex-1) * nTF + spatialFrequencyIndex)
            t=ceil(thisAction/ nSF);
            s=1+rem(thisAction, nTF); %  Should be 1+rem(thisAction-1,nTF)
            thisTF=tfList(t);
            thisSF=sfList(s);
            fprintf('\nRunning tf %d, sf %d',thisTF,thisSF);
            
          
        
            d=flytv_PlaidDemo3(thisTF,thisSF);     % This function runs the grating and acquires data. If we did the screen opening outside the loop (or made it static?)
            % We might not have to
            % open the screen each
            % time around.
            
            
            
            %finalData.triggerTime=d.TriggerTime; % Extract the data into a new struct because DAQ objects don't save nicely
            %finalData.Data=d.Data;
            %finalData.TimeStamps=d.TimeStamps;
            %finalData.Source=d.Source;
            %finalData.EventName=d.EventName;
            %finalData.comment='Spatial_temporal_Sweep_W-2';
            %finalData.thisTF=thisTF;
            %finalData.thisSF=thisSF;
            %finalData.thisTFIndex=t;
            %finalData.thisSFIndex=s;
            %finalData.now=now;
            %finalData.r=r;
            
           % infoSet.thisTF=thisTF;
            %infoSet.thisSF=thisSF;
            %infoSet.thisTFIndex=t;
            %infoSet.thisSFIndex=s;
            %infoSet.r=r;
            %infoSet.nTF=nTF;
            %infoSet.nSF=nSF;
            %infoSet.thisAction=thisAction;
            %infoSet.tfList=tfList;
            %infoSet.sfList=sfList;
            %infoSet.now=now;
            %infoSet.comment= finalData.comment;
            
       
            
            %filename=fullfile(datadir,[int2str(t),'_',int2str(s),'_',int2str(thisrun),'_',datestr(flyTV_startTime,30),'.mat'])
            %save(filename,'finalData');
            
            %dataSet(temporalFrequencyIndex,spatialFrequencyIndex,thisrun,:)=finalData.Data(:); % Put the extracted data into an array tf x sf x nrepeats
            %metaData{temporalFrequencyIndex,spatialFrequencyIndex,thisrun}=infoSet; % Put the extracted data into an array tf x sf x nrepeats

            
            
        end % Next spatial frequency
    end % Next temporalFrequency
end    

%filename=fullfile(datadir,['flyTV_',datestr(flyTV_startTime,30),'.mat'])
%save(filename);






