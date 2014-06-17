%load('/Users/alexwade/Downloads/Sweep1 08.04.14.mat') % it is possible to browse files using uigetfile
clear all
close all;
dataDir=uigetdir;
fList=dir(fullfile(dataDir,'*.mat'))

nFlies=length(fList);
% Generate an empty matrix of NaNs 

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
            datStruct(thisFly,thisRep,:,:)=thisD.data(thisRep,:,:);
            tfList(thisFly,thisRep,:)=tf(thisRep,:);
            sfList(thisFly,thisRep,:)=sf(thisRep,:);

    end
    
end


%% For each fly, we now have a set of unsorted data (nReps * nConditions x nsamples x nSecs)
% And a corresponding sf and tf for each one.
% Using unique we can assign an x and y index to each condition
 for thisFly=1:nFlies
     for thisRep=1:nRepeats
         thisSfList=sfList(thisFly,thisRep,:);
         thisTfList=tfList(thisFly,thisRep,:);
         [uniqueSF,sfIndexOut,sfIndexIn]=unique(thisSfList);
         [uniqueTF,tfIndexOut,tfIndexIn]=unique(thisTfList);
         nTrials=length(tfIndexIn);
         for thisTrial=1:nTrials
         fullDat(thisFly,thisRep,tfIndexIn(thisTrial),sfIndexIn(thisTrial),:)=datStruct(thisFly,thisRep,thisTrial,:);
         end
         
     end
 end

%%
% Now do some (coherent) averaging. Also crop out the right size of analysis time. NOTE: For the frequencies used
% here, we have all integers so we can use any set of 1Sec periods
durSecs=10;
croppedDat=fullDat(:,:,:,:,1001:(durSecs*1000+1000));


% Compute the FT
ftAcrossReps=(fft(croppedDat,[],5)/(durSecs*1000));

fMeanAcrossReps=(squeeze(mean(ftAcrossReps,2)));


freqsToExtract=(uniqueTF*durSecs);
for thisFly=1:nFlies
    for thisTF=1:length(uniqueTF)
        for thisSF=1:length(uniqueSF)
            
            for thisHarmonic=1:2
                
                currF=freqsToExtract(thisTF)*thisHarmonic+1;
                extractedAmps(thisFly,thisTF,thisSF,thisHarmonic)=fMeanAcrossReps(thisFly,thisTF,thisSF,currF); %,freqsToExtract(thisTrial));
                ampPower(thisFly,thisTF,thisSF,thisHarmonic)=sqrt(sum(fMeanAcrossReps(thisFly,thisTF,thisSF,:).^2,4));
                coh(thisFly,thisTF,thisSF,thisHarmonic)=abs(extractedAmps(thisFly,thisTF,thisSF,thisHarmonic))./ampPower(thisFly,thisTF,thisSF,thisHarmonic);
         
            end % Next harmonic
        end % Next sf
    end % Next TF
end % Next Fly

%%

mExtracted=abs(squeeze(mean((extractedAmps))));
figure(10);
hold off;
subtightplot(1,3,1,.03);
imagesc(squeeze(mExtracted(:,:,1)));colorbar;
ylabel('TF Hz');
xlabel('SF cpd');
set(gca,'YTickLabel',uniqueTF );
set(gca,'XTickLabel',uniqueSF);
colormap hot; colorbar;
subtightplot(1,3,2,.03);
imagesc(squeeze(mExtracted(:,:,2)));colorbar;
ylabel('TF Hz');
xlabel('SF cpd');
set(gca,'YTickLabel',uniqueTF );
set(gca,'XTickLabel',uniqueSF);
    colormap hot; colorbar;
subtightplot(1,3,3,.03);
    imagesc(squeeze(mExtracted(:,:,2)./squeeze(mExtracted(:,:,1))));colorbar;
ylabel('TF Hz');
xlabel('SF cpd');
set(gca,'YTickLabel',uniqueTF );
set(gca,'XTickLabel',uniqueSF);
    colormap hot; colorbar;
return;
%%

[uniqueTF,d,tfInds]=unique(tf);
[uniqueSF,d,sfInds]=unique(sf);

nTF=length(uniqueTF);
nSF=length(uniqueSF);


nSecs=9; % number of good 1sec bins
nPreBin=1; % In secs
nPostBin=1; % In secs
sampleFreq=1000; % Samples per sec

% r contains the randomized sequence.
% Zero this dataset so that we can fill it in.
outAmplitude1F1(thisTrial,:,:)=zeros(nTF,nSF);
outAmplitude2F1(thisTrial,:,:)=zeros(nTF,nSF);
outNoise(thisTrial,:,:)=zeros(nTF,nSF);

for thisTFIndex=1:nTF
    for thisSFIndex=1:nSF
        allData{thisTFIndex,thisSFIndex}=[];
    end
end

for thisTrial=1:nTrials
    thisTFIndex=tfInds(thisTrial);
    thisSFIndex=sfInds(thisTrial);
    allData{thisTFIndex,thisSFIndex}=cat(1,allData{thisTFIndex,thisSFIndex},data(thisTrial,:));
    tf
end

[nr,nt]=size(allData{1});

ds=zeros(6,6,nr,nt);
tds=zeros(6,6,nr,nt-2000);
% Compute the appropriate analysis duration for this frequency...
dpy.frameRate=144;
for thisTFIndex=1:nTF
    for thisSFIndex=1:nSF
        disp(thisTFIndex)
        disp(thisSFIndex)
        
        ds=squeeze(allData{thisTFIndex,thisSFIndex});
        
        [totalAnalysisDurationSecs,respFreq] = flytv_maxAnalysisDuration(dpy,uniqueTF(thisTFIndex),nSecs);
        totalAnalysisSamples=totalAnalysisDurationSecs*1000;
        
        % timeSeriesData=allRespData.Data(1001:(totalAnalysisSamples+1000));
        
        tds=ds(:,(1001:round((totalAnalysisSamples+1000))));
        
        ftds=fft(tds,[],2)/totalAnalysisSamples;%
%         
%         
%         tds=ds(:,(sampleFreq*nPreBin+1):(end-sampleFreq*nPostBin));
%         ftds=fft(tds,[],2);%
        
       % respFreq=nSecs*uniqueTF(thisTFIndex);
        
        rAmp(thisTFIndex,thisSFIndex)=mean(squeeze(abs(ftds(:,respFreq+1))));
        rAmp2(thisTFIndex,thisSFIndex)=mean(squeeze(abs(ftds(:,respFreq*2+1))));
        stAmp(thisTFIndex,thisSFIndex)=std(squeeze(abs(ftds(:,respFreq+1))),[],1);
        stAmp2(thisTFIndex,thisSFIndex)=std(squeeze(abs(ftds(:,respFreq*2+1))),[],1);
        
    end
end



%rAmp=rAmp./stAmp;
%rAmp2=rAmp2./stAmp2;



figure(1);

subplot(3,1,1);
imagesc(rAmp);
set(gca,'XTick',[1 2 3 4 5 6] );
set(gca,'XTickLabel',[2.25 4.5 9 18 24 36] );
set(gca,'YTick',[1 2 3 4 5 6] );
set(gca,'YTickLabel',[0.014 0.028 0.056 0.11 0.22 0.44]);
xlabel('Temporal Frequency (Hz)')
ylabel('Spatial Frequency (CPD)')
colorbar;
subplot(3,1,2);
imagesc(rAmp2);
set(gca,'XTick',[1 2 3 4 5 6] );
set(gca,'XTickLabel',[2.25 4.5 9 18 24 36] );
set(gca,'YTick',[1 2 3 4 5 6] );
set(gca,'YTickLabel',[0.014 0.028 0.056 0.11 0.22 0.44]);
xlabel('Temporal Frequency (Hz)')
ylabel('Spatial Frequency (CPD)')
colormap hot;
colorbar;
subplot(3,1,3);
imagesc(rAmp2./rAmp);
set(gca,'XTick',[1 2 3 4 5 6] );
set(gca,'XTickLabel',[2.25 4.5 9 18 24 36] );
set(gca,'YTick',[1 2 3 4 5 6] );
set(gca,'YTickLabel',[0.014 0.028 0.056 0.11 0.22 0.44]);
xlabel('Temporal Frequency (Hz)')
ylabel('Spatial Frequency (CPD)')
colormap hot;
colorbar;
 print(gcf, '-dpdf', '-opengl', 'output.pdf')
