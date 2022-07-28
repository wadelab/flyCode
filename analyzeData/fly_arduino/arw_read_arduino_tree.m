function [outData, successArray]=arw_read_arduino_dir(fInputDir)
%function outData=arw_read_arduino_dir(fInputDir, varargin)
% Reads the data from an arduino directory
% Returns it as a block subs x conditions x time
% + some associated metadata
% Modified from CE´s code  read_arduino_tree
% ARW 07/21/22
% Unlike CE code, this does not traverse the dir tree , just files from a
% single dir

% Check the input dir exists
assert(exists(fInputDir,'dir'),'Input directory not found');

allFiles = dir([fullfile(fInputDir, '*.*')]); % matlab cannot do a case-insensitive dir so we list all files and then sub-select using strcmpi
SVPfilesIndices=endsWith(lower({allFiles.name}),'.svp');
SVPfiles=allFiles(find(SVPfilesIndices));



%% now we have a list of all the files with .SVP in that tree
if (length(SVPfiles) ==0)
   disp(['Exiting becuase No SVP files were found in ',fInputDir]);
   return 
end

% Deblank
for i=1:length(SVPfiles)
    SVPfiles{i} = deblank(SVPfiles{i});
end


%% read all the rest of them (well, the first 40)

maxFilesToRead = length(SVPfiles);
for i=1:min(length(SVPfiles),maxFilesToRead)
  
    fName=fullfile(SVPfiles(i).folder, SVPfiles(i).name);
    fprintf('\nReading file %s (index %d): ',fName,i);
    [outData{i}, successArray(i)] = arw_read_arduino_file ( fName  );
    allMeanFFT(i,:,:)=outData{i}.meanFFT;
    
end
groupMeanFFT=abs(squeeze(mean(allMeanFFT)));
groupSEMFFT=abs(squeeze(std(allMeanFFT)/sqrt(i)));

%%
figure(1);
% 1F1
subplot(2,2,1);
hold off
F1=12;
criticalF=F1*4+1;
shadedErrorBar(a.meanContrasts(1:5),groupMeanFFT(1:5,criticalF),groupSEMFFT(1:5,criticalF));
hold on;
shadedErrorBar(a.meanContrasts(6:9),groupMeanFFT(6:9,criticalF),groupSEMFFT(6:9,criticalF),'lineprops','r');
grid on
set(gca,'XScale','log');

%2F1
subplot(2,2,2);
hold off
F1=24;
criticalF=F1*4+1;
shadedErrorBar(a.meanContrasts(1:5),groupMeanFFT(1:5,criticalF),groupSEMFFT(1:5,criticalF));
hold on;
shadedErrorBar(a.meanContrasts(6:9),groupMeanFFT(6:9,criticalF),groupSEMFFT(6:9,criticalF),'lineprops','r');
grid on
set(gca,'XScale','log');

% 1F2
subplot(2,2,3);
hold off
F1=15;
criticalF=F1*4+1;
shadedErrorBar(a.meanContrasts(1:5),groupMeanFFT(1:5,criticalF),groupSEMFFT(1:5,criticalF));
hold on;
shadedErrorBar(a.meanContrasts(6:9),groupMeanFFT(6:9,criticalF),groupSEMFFT(6:9,criticalF),'lineprops','r');
grid on
set(gca,'XScale','log');

% 2F2
subplot(2,2,4);
hold off
F1=30;
criticalF=F1*4+1;
shadedErrorBar(a.meanContrasts(1:5),groupMeanFFT(1:5,criticalF),groupSEMFFT(1:5,criticalF));
hold on;
shadedErrorBar(a.meanContrasts(6:9),groupMeanFFT(6:9,criticalF),groupSEMFFT(6:9,criticalF),'lineprops','r');
grid on
set(gca,'XScale','log');
