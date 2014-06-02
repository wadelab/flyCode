%load('/Users/alexwade/Downloads/Sweep1 08.04.14.mat') % it is possible to browse files using uigetfile
clear all
close all;
dataDir=uigetdir;

%%
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
    cyclesPerData=(dur-1)*freqs;
    rawData=thisD.data(:,:,(1001:end));
    fRaw=fft(rawData,[],3); % Ft down time
    goodComps=(fRaw(:,:,cyclesPerData+1));
    [seq,ishuffleSeq]=sort(thisD.shuffleSeq);
    
    mGoodComps(thisFly,thisD.shuffleSeq,:)=mean((goodComps(:,:,:)));
    
    
    
    
    
    
end
%%
unmaskedInds=[1:5];
maskedInds=[6:10];
mvals=squeeze(mean(abs(mGoodComps),1));
stVals=squeeze(std(mGoodComps,[],1));
semVals=stVals/sqrt(nFlies);

figure(10);
cLevels1=thisD.probeCont(unmaskedInds);
cLevels2=thisD.probeCont(maskedInds);
subplot(3,1,1);

imagesc(abs(mGoodComps(:,:,1)));

subplot(3,1,2);
hold off;


h1=errorbar(cLevels1+.01,mvals(unmaskedInds),semVals(unmaskedInds),'k');
hold on;
h2=errorbar(cLevels2+.01,mvals(maskedInds),semVals(maskedInds),'r');set(gca,'XScale','Log');
set(h1,'LineWidth',2);
set(h2,'LineWidth',2);

grid on;

% Also plot the mask response


subplot(3,1,3);

hold off;


h1=errorbar(cLevels1+.01,mvals(unmaskedInds,2),semVals(unmaskedInds,2),'k');
hold on;
h2=errorbar(cLevels2+.01,mvals(maskedInds,2),semVals(maskedInds,2),'r');set(gca,'XScale','Log');
set(h1,'LineWidth',2);
set(h2,'LineWidth',2);

grid on;

return;
%%
