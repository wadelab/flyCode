%This code reads a 'fit' file of bootstrap parameters and plots the data and then does anova on it

close all;
clear all; 

[fileToLoad,pathToLoad]=uigetfile('*fitTemp*.mat','Load fit file');
[pathstr, name, ext] = fileparts(fileToLoad);
filebaseName = [pathToLoad,name, '_fitted_Bootf'];
load(fullfile(pathToLoad,fileToLoad));

%%load(fullfile('work.mat'));
%% 
%% ****************************
% We now have some lovely bootstrapped parameters for all mask conditions
% % The indices into bootFitParams are
% [phenotypeIndex, maskIndex, frequencyComponentIndex, bootStrapInstance, paramIndex]
% The order of the param indices is the same as above: Rmax, c50, n, R0

%% housekeeping 
harmonicNames = {'1F1','1F2';'2F1','2F2'};
paramNames = {'Rmax', 'c50', 'n', 'R0'}; %R0 is always zero

xToPlot = linspace(0,length(fittedNames),length(fittedNames));
if length(fittedNames) < 4 % try 4
    sStyle = 'horizontal' ;
    xAngle = 0 ;
else
    sStyle = 'inline' ; 
    xAngle = 45 ;
end

for phenotypeIndex=1:length(fittedNames)
    tmpName = fittedNames{phenotypeIndex};
    tmpName = strrep (tmpName,'all', '');
    tmpName = strrep (tmpName,'_', ' ');
    fittedNames{phenotypeIndex}= tmpName;
end

%% write out the boot fits in an Excel -freiendly format

% in this case we just write out the last bit (rows 24-35) of the masked
% data ( thisMaskCondition = 2:2 )
fID = fopen([filebaseName,'.csv'], 'w+');


fprintf(fID,' Freq, Param, CI1, CI2, Phenotype\n');

for iPhenotype=24:35
    for iFreq = 1:2
        for iParam = 1:2 % just write RMax and c50
            for thisMaskCondition = 2:2
                fprintf(fID,'%s, %s, %0.5e, %0.5e, %0.5e, %s \n',  harmonicNames{iFreq},  paramNames{iParam},  confInt(iPhenotype,thisMaskCondition,iFreq,1,iParam),  mean(bootFitParams(iPhenotype,thisMaskCondition,iFreq,:,iParam)),confInt(iPhenotype,thisMaskCondition,iFreq,2,iParam), fittedNames{iPhenotype});
            end % mask
        end  % iParam
    end % iFreq
end %iPhen
%quit
