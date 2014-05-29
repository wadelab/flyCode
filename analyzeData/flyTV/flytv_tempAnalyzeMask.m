%load('/Users/alexwade/Downloads/Sweep1 08.04.14.mat') % it is possible to browse files using uigetfile
clear all
close all;
dataDir=uigetdir
fList=dir(fullfile(dataDir,'*.mat'))

nFlies=length(fList);

for thisFly=1:nFlies
    fName=fullfile(dataDir,fList(thisFly).name)
    
    
    dataSetName=fullfile(fName); % Fullfile generates a legal filename on any platform
    thisD=load(dataSetName);
    [nReps,nContCombos]=size(thisD.metaData);
    freqs=thisD.stim.temporal.frequency;
    dur=thisD.stim.temporal.duration;
    disp thisFly
    
    for thisRep=1:nReps
        for thisCombo=1:nContCombos
    fprintf('\n%d,%d\n',thisRep,thisCombo);
    
            thisMD=thisD.metaData{thisRep,thisCombo};
            probeCont(thisRep,thisCombo)=thisMD.stim.cont(1);
            maskCont(thisRep,thisCombo)=thisMD.stim.cont(2);
        end
    end
    
    % Extract the responses at the modulation frequencies
    cyclesPerData=(dur-1)*freqs*2;
    rawData=thisD.data(:,:,(1001:end));
    fRaw=fft(rawData,[],3); % Ft down time
    goodComps=(fRaw(:,:,cyclesPerData+1));
    [seq,ishuffleSeq]=sort(thisD.shuffleSeq);
    
    mGoodComps(thisFly,thisD.shuffleSeq,:)=(mean((goodComps(:,:,:))));

    
    
    
    
    
end
%%
pc1=1:7
pc2=8:12;

mvals=abs(squeeze(mean(abs(mGoodComps))));
% allAng=angle(mGoodComps)-repmat(angle(mGoodComps(:,7,1)),[1 12 2]);
% avals=squeeze(mean((allAng)));

stVals=squeeze(std((mGoodComps)));
semVals=stVals/sqrt(nFlies);

figure(10);
cLevels1=thisD.probeCont(pc1);
cLevels2=thisD.probeCont(pc2);
subplot(3,1,1);

imagesc(abs(mGoodComps(:,:,1)));

subplot(3,1,2);
hold off;


h1=errorbar(cLevels1+.01,mvals(pc1),semVals(pc1),'k');
hold on;
h2=errorbar(cLevels2+.01,mvals(pc2),semVals(pc2),'r');set(gca,'XScale','Log');
set(h1,'LineWidth',2);
set(h2,'LineWidth',2);

grid on;

% Also plot the mask response


subplot(3,1,3);

hold off;


h1=errorbar(cLevels1+.01,mvals(pc1,2),semVals(pc1,2),'k');
hold on;
h2=errorbar(cLevels2+.01,mvals(pc2,2),semVals(pc2,2),'r');set(gca,'XScale','Log');
set(h1,'LineWidth',2);
set(h2,'LineWidth',2);

grid on;
dataDir
% 
% figure(11);
% hold off;
% cLevels1=thisD.probeCont(pc1);
% cLevels2=thisD.probeCont(pc2);
% 
% 
% polar((180/pi)*(avals(pc1,1))',cLevels1+.01,'k');
% hold on;
% 
% polar((180/pi)*(avals(pc2,1))',cLevels2+.01,'r');
% hold off;
% return;
%%
