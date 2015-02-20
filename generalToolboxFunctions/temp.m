% What is this?
% This is an example of an analysis script that you can use to look at your
% data, perform stats etc. 
% DO NOT EDIT THIS SCRIPT (your edits will just be lost the next time you
% sync to the GITHUB)
% Instead, copy this script to your local directory and write all your
% analyses there. Each person will have a set of analysis scripts for their
% particular project, paper, whatever.
% If you like, you can call your scripts something like
% analyzeData_ARW_Figure1_PDProject.m
% 
%
% This script shows you how to read the data structure that is now saved
% out from the principle 'new' and 'old' analysis routines
% (fly_analyzeDirectory.m or selectLoadAnalyzeData_....m
% It is agnostic as to where the data came from. But some things (like the
% mean spectrum) aren't saved out in the new format yet.
%
% If you are feeling particularly keen, you can write your own functions to
% encapsulate things like bootstrapping, ANOVAs etc.
% ARW 051213


clear all;
close all;



IGNORE_PHOTODIODE_FLAG=1; % Normally we don't want to waste time processing the photodiode phenotype since it's a) not physiologically interesting and b) statistically different from everything else


%[fileToLoad,pathToLoad]=uigetfile('*Analysis*.mat','Load analysis file');
%[pathstr, name, ext] = fileparts(fileToLoad);
%b = [pathToLoad,name, '_analysed_',datestr(now,30)];


%load(fullfile(pathToLoad,fileToLoad)); % This is the file you got from the directory analysis script. It will place a structure calles 'analysisStruct' in the workspace
% ** Obviously you replace the filename above with the one that you saved
% out from the selectLoadAnalyze... script' Or make the call above a
% uigetfile to browse .

   load ('work.mat');

% We are about to fit all the 1F1 and 2F1 data with a hyperbolic ratio function...
fComponentList=[1 3];
paramNameList={'Rmax','c50','n','R0'};
phenotypeIndex=0;
nPhenotypes=length(analysisStruct.allFlyDataCoh);
for thisPhenotype=1:nPhenotypes
    if (strcmp(analysisStruct.phenotypeName{thisPhenotype},'Photodiode') & (IGNORE_PHOTODIODE_FLAG))
        disp('Skipping photodiode');
    else
        phenotypeIndex=phenotypeIndex+1;
        for thisFComponentIndex=1:2
            for thisMaskType=1:2
                % Loop over all fly types
                disp('Fitting');
                tic
                thisPhenotypeMeanData=squeeze(mean(abs(analysisStruct.allFlyDataCoh{thisPhenotype}),1));
                
                [fittedCRFParams(phenotypeIndex,thisFComponentIndex,thisMaskType,:)]=fly_fitHyperData(analysisStruct.params,analysisStruct.contRange,squeeze(abs(thisPhenotypeMeanData(fComponentList(thisFComponentIndex),:,thisMaskType)))); % In fact inc or coh data are the same in this case since the fitting is done on magnitude
                tmpName = analysisStruct.phenotypeName{thisPhenotype}
                tmpName = strrep (tmpName,'all', '');
                tmpName = strrep (tmpName,'_', ' ');
                fittedNames{phenotypeIndex}= tmpName;
                
                % The fitted params are Rmax, c50, n, R0 (which is fixed at 0)
                toc
            end % Next mask type
        end % Next Freq component
    end % End check on photodiode
end % Next phenotype

%% As an example, take a look at the 1F1 Rmax parameter across phenotypes for
% masked and unmasked
% The indices into fittedCRFParams are
% [phenotypeIndex, componentIndex, maskIndex, paramIndex]


RmaxParam=squeeze(fittedCRFParams(:,1,:,1))
figure('Name', '1F1 masked and unmasked Rmax');
bar(RmaxParam);
legend({'Unmasked','Masked'});
set(gca,'XTickLabel',fittedNames);
title('1F1 masked and unmasked Rmax');

% Here's another example - look at the 2F1 Rmax...
RmaxParam=squeeze(fittedCRFParams(:,2,:,1))
figure('Name', '2F1 masked and unmasked Rmax');
bar(RmaxParam);
legend({'Unmasked','Masked'});
set(gca,'XTickLabel',fittedNames);
title('2F1 masked and unmasked Rmax');

