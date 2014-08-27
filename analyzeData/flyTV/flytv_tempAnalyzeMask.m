%load('/Users/alexwade/Downloads/Sweep1 08.04.14.mat') % it is possible to browse files using uigetfile
clear all
close all;
dataDir=uigetdir;
fList=dir(fullfile(dataDir,'flyTV_*.mat'))

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
   % fprintf('\n%d,%d\n',thisRep,thisCombo);
    
            thisMD=thisD.metaData{thisRep,thisCombo};
            probeCont(thisRep,thisCombo)=thisMD.stim.cont(1);
            maskCont(thisRep,thisCombo)=thisMD.stim.cont(2);
        end
    end
    
    % Extract the responses at the modulation frequencies
    cyclesPerData=[(dur-1)*freqs(1)*2,;(dur-1)*(freqs(1)*2+freqs(2)*2)];
    rawData=thisD.data(:,:,(1001:end));
    fRaw=fft(rawData,[],3); % Ft down time
    goodComps=(fRaw(:,:,cyclesPerData+1));
    [seq,ishuffleSeq]=sort(thisD.shuffleSeq);
    
    mGoodComps(thisFly,thisD.shuffleSeq,:)=(mean((goodComps(:,:,:)))); % This is the complex (coherent) mean within a single animal
    
    
    
    
    
    
end
%%
mvals=abs(squeeze(mean(abs(mGoodComps)))); % This is the incoherent (abs) mean between animals
stVals=squeeze(std((mGoodComps)));
semVals=stVals/sqrt(nFlies);

figure(10);
cLevels1=thisD.probeCont(1:7);
cLevels2=thisD.probeCont(8:12);
subplot(3,1,1);

imagesc(abs(mGoodComps(:,:,1)));

subplot(3,1,2);
hold off;


h1=errorbar(cLevels1+.01,mvals(1:7),semVals(1:7),'k');
hold on;
h2=errorbar(cLevels2+.01,mvals(8:12),semVals(8:12),'r');set(gca,'XScale','Log');
set(h1,'LineWidth',2);
set(h2,'LineWidth',2);

grid on;
title('2F1 responses');
legend({'Unmasked','Masked'});

% Also plot the mask response


subplot(3,1,3);

hold off;


h1=errorbar(cLevels1+.01,mvals(1:7,2),semVals(1:7,2),'k');
hold on;
h2=errorbar(cLevels2+.01,mvals(8:12,2),semVals(8:12,2),'r');set(gca,'XScale','Log');
set(h1,'LineWidth',2);
set(h2,'LineWidth',2);

grid on;
title('2F2 responses');
legend({'Unmasked','Masked'});

return;
%%
