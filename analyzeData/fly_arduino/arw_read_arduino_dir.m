function [outData, successArray]=arw_read_arduino_dir(fInputDir,figureOffset)
%function outData=arw_read_arduino_dir(fInputDir, varargin)
% Reads the data from an arduino directory
% Returns it as a block subs x conditions x time
% + some associated metadata
% Modified from CE´s code  read_arduino_tree
% ARW 07/21/22
% Unlike CE code, this does not traverse the dir tree , just files from a
% single dir

% Check the input dir exists
assert(exist(fInputDir,'dir'),'Input directory not found');
if (nargin<2)
    figureOffset=1; % First figure to plot
end

allFiles = dir([fullfile(fInputDir, '*.*')]); % matlab cannot do a case-insensitive dir so we list all files and then sub-select using strcmpi
SVPfilesIndices=find(endsWith(lower({allFiles.name}),'.svp'));
SVPfilesIndices=[SVPfilesIndices,find(endsWith(lower({allFiles.name}),'.svp.txt'))];

SVPfiles=allFiles((SVPfilesIndices));
 


%% now we have a list of all the files with .SVP in that tree
if (length(SVPfiles) ==0)
   disp(['Exiting becuase No SVP files were found in ',fInputDir]);
   return 
end

%% read all the rest of them (well, the first 40)

maxFilesToRead = length(SVPfiles);
for i=1:min(length(SVPfiles),maxFilesToRead)
  
    fName=fullfile(SVPfiles(i).folder, SVPfiles(i).name);
    fprintf('\nReading file %s (index %d): ',fName,i);
    [outData{i}, successArray(i)] = arw_read_arduino_file ( fName  );
    allMeanFFT(i,:,:)=outData{i}.meanFFT;
    
end
a=outData{1};
groupMeanFFT=abs(squeeze(mean(allMeanFFT)));
groupAngleFFT=angle(squeeze(mean(allMeanFFT)));
groupSEMFFT=abs(squeeze(std(allMeanFFT)/sqrt(i)));
%%
freqsToPlot=[12 24 15 30 27 3];
plotIndex=1;
for thisFreq=1:length(freqsToPlot)
    

figure(figureOffset);
hold off;
% 1F1 Amp
subplot(2,3,plotIndex);
hold off

criticalF=freqsToPlot(thisFreq)*4+1;
shadedErrorBar(a.meanContrasts(1:5,2),groupMeanFFT(1:5,criticalF),groupSEMFFT(1:5,criticalF));
hold on;
shadedErrorBar(a.meanContrasts(6:9,2),groupMeanFFT(6:9,criticalF),groupSEMFFT(6:9,criticalF),'lineprops','r');
grid on
set(gca,'XScale','log');
set(gca,'YLim',[0 80]);

set(gcf,'Name',fInputDir);
title(num2str(freqsToPlot(plotIndex)));

figure(figureOffset+1);
hold off;
% 1F1 Compass
subplot(2,3,plotIndex);

hold off
compass(groupAngleFFT(6:9,criticalF),groupMeanFFT(6:9,criticalF),'r');
hold on;
compass(groupAngleFFT(1:5,criticalF),groupMeanFFT(1:5,criticalF))
title(num2str(freqsToPlot(plotIndex)));

grid on
plotIndex=plotIndex+1;

set(gcf,'Name',fInputDir);
end

