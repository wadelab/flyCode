%load('/Users/alexwade/Downloads/Sweep1 08.04.14.mat') % it is possible to browse files using uigetfile
clear all
close all;
dataDir=uigetdir;
fList=dir(fullfile(dataDir,'*.mat'))

nTrials=length(fList);

for thisTrial=1:nTrials
    fName=fullfile(dataDir,fList(thisTrial).name)
    
    
    dataSetName=fullfile(fName); % Fullfile generates a legal filename on any platform
    thisD=load(dataSetName);
    tf(thisTrial)=thisD.finalData.thisTF;
    sf(thisTrial)=thisD.finalData.thisSF;
    data(thisTrial,:)=thisD.finalData.Data';
    timeStamps(thisTrial,:)=thisD.finalData.TimeStamps';
    
end
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
    
    ds=zeros(5,5,nr,nt);
    tds=zeros(5,5,nr,nt-2000);
    
       for thisTFIndex=1:nTF
        for thisSFIndex=1:nSF
            disp(thisTFIndex)
            disp(thisSFIndex)
            
            ds=squeeze(allData{thisTFIndex,thisSFIndex});
           
            tds=ds(:,(sampleFreq*nPreBin+1):(end-sampleFreq*nPostBin));
            ftds=fft(tds,[],2);%
            
            respFreq=nSecs*uniqueTF(thisTFIndex);
            
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
         colorbar;
          subplot(3,1,2);
       imagesc(rAmp2);
       colormap hot;
       colorbar;      subplot(3,1,3);
       imagesc(rAmp2./rAmp);
       colormap hot;
       colorbar;
       
       
       
     