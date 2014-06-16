%load('/Users/alexwade/Downloads/Sweep1 08.04.14.mat') % it is possible to browse files using uigetfile
clear all
close all;
dataDir=uigetdir;
fList=dir(fullfile(dataDir,'*.mat'))

nFlies=length(fList);

%%
for thisFly=1:nFlies
    fName=fullfile(dataDir,fList(thisFly).name)
    
    
    dataSetName=fullfile(fName); % Fullfile generates a legal filename on any platform
    
    thisD=load(dataSetName);
    [nRepeats,nTrials,nSamples]=size(thisD.data)% Data is saved as nReps x nConditions x nSamples. It has to be re-sorted
    % Loop over trials extracting sf and tf for each one.
    for thisRep=1:nRepeats
        for thisTrial=1:nTrials
            
            trialMetadata=thisD.metaData{thisRep,thisTrial};
            sf(thisRep,thisTrial)=trialMetadata.stim.spatial.frequency(1); % Assumes both gratings have same Sf
            tf(thisRep,thisTrial)=trialMetadata.stim.temporal.frequency(1); % Assumes both gratings have same tf
            
            
            
            shuffleSeq(thisRep,:)=trialMetadata.shuffleSeq; % Shuffleseq is the randomized presentation index
            [sSeq,i]=sort(shuffleSeq(thisRep,:));
            
        end
            datStruct(thisFly,thisRep,:,:)=thisD.data(thisRep,i,:);
            sortedTfList(thisFly,thisRep,:)=tf(thisRep,i);
            sortedSfList(thisFly,thisRep,:)=sf(thisRep,i);


    end
    
    
    
    
end

% Now do some (coherent) averaging. Also crop out the right size of analysis time. NOTE: For the frequencies used
% here, we have all integers so we can use any set of 1Sec periods
durSecs=10;
meanAcrossReps=squeeze(mean(datStruct(:,:,:,1001:(durSecs*1000+1000)),2));


% Compute the FT
fMeanAcrossReps=(fft(meanAcrossReps,[],3)/(durSecs*1000));

%%
freqsToExtract=squeeze(sortedTfList(1,1,:))*2*durSecs+1;

for thisTrial=1:nTrials
    for thisFly=1:nFlies
        extractedAmps(thisFly,thisTrial)=fMeanAcrossReps(thisFly,thisTrial,freqsToExtract(thisTrial));
    end
end


mExtracted=abs(squeeze(mean(extractedAmps)));
figure(10);
hold off;
;
imagesc(reshape(mExtracted,7,8));colorbar;
ylabel('SpatialFrequency (CPD)');
xlabel('TemporalFrequency (Hz)');

set(gca,'XTick',[1 2 3 4 5 6 7 8] );
set(gca,'XTickLabel',[1 2 4 6 8 12 18 36]);
set(gca,'YTick',[1 2 3 4 5 6 7] );
set(gca,'YTickLabel',[.014 .028 .056 .11 .22 .44 .88]);


axis image;
colormap hot;
return;
%%

%[uniqueTF,d,tfInds]=unique(tf);
%[uniqueSF,d,sfInds]=unique(sf);

%nTF=length(uniqueTF);
%nSF=length(uniqueSF);


%nSecs=9; % number of good 1sec bins
%nPreBin=1; % In secs
%nPostBin=1; % In secs
%sampleFreq=1000; % Samples per sec

% r contains the randomized sequence.
% Zero this dataset so that we can fill it in.
%outAmplitude1F1(thisTrial,:,:)=zeros(nTF,nSF);
%outAmplitude2F1(thisTrial,:,:)=zeros(nTF,nSF);
%outNoise(thisTrial,:,:)=zeros(nTF,nSF);

%for thisTFIndex=1:nTF
 %   for thisSFIndex=1:nSF
 %       allData{thisTFIndex,thisSFIndex}=[];
  %  end
%end

%for thisTrial=1:nTrials
  %  thisTFIndex=tfInds(thisTrial);
   % thisSFIndex=sfInds(thisTrial);
    %allData{thisTFIndex,thisSFIndex}=cat(1,allData{thisTFIndex,thisSFIndex},data(thisTrial,:));
    %tf
%end

%[nr,nt]=size(allData{1});

%ds=zeros(6,6,nr,nt);
%tds=zeros(6,6,nr,nt-2000);
% Compute the appropriate analysis duration for this frequency...
%dpy.frameRate=144;
%for thisTFIndex=1:nTF
 %   for thisSFIndex=1:nSF
  %      disp(thisTFIndex)
   %     disp(thisSFIndex)
        
    %    ds=squeeze(allData{thisTFIndex,thisSFIndex});
        
     %   [totalAnalysisDurationSecs,respFreq] = flytv_maxAnalysisDuration(dpy,uniqueTF(thisTFIndex),nSecs);
      %  totalAnalysisSamples=totalAnalysisDurationSecs*1000;
        
        % timeSeriesData=allRespData.Data(1001:(totalAnalysisSamples+1000));
        
       % tds=ds(:,(1001:round((totalAnalysisSamples+1000))));
        
        %ftds=fft(tds,[],2)/totalAnalysisSamples;%
%         
%         
%         tds=ds(:,(sampleFreq*nPreBin+1):(end-sampleFreq*nPostBin));
%         ftds=fft(tds,[],2);%
        
       % respFreq=nSecs*uniqueTF(thisTFIndex);
        
        %rAmp(thisTFIndex,thisSFIndex)=mean(squeeze(abs(ftds(:,respFreq+1))));
        %rAmp2(thisTFIndex,thisSFIndex)=mean(squeeze(abs(ftds(:,respFreq*2+1))));
        %stAmp(thisTFIndex,thisSFIndex)=std(squeeze(abs(ftds(:,respFreq+1))),[],1);
        %stAmp2(thisTFIndex,thisSFIndex)=std(squeeze(abs(ftds(:,respFreq*2+1))),[],1);
        
  %  end
%end



%rAmp=rAmp./stAmp;
%rAmp2=rAmp2./stAmp2;


