%This code reads a 'fit' file of bootstrap parameters and plots the data and then does anova on it

close all;
clear all;

%[fileToLoad,pathToLoad]=uigetfile('*fitTemp*.mat','Load fit file');
%[pathstr, name, ext] = fileparts(fileToLoad);
%b = [pathToLoad,name, '_fitted_',datestr(now,30)];


load(fullfile('work.mat'));
%% 
%% ****************************
% We now have some lovely bootstrapped parameters for all mask conditions
% % The indices into bootFitParams are
% [phenotypeIndex, maskIndex, frequencyComponentIndex, bootStrapInstance, paramIndex]
% The order of the param indices is the same as above: Rmax, c50, n, R0

%% housekeeping 
harmonicNames = {'1F1','1F2';'2F1','2F2'};
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
fID = fopen('work.csv', 'w+');
fprintf(fID,' Freq, RMax BP, Phenotype\n');

bf_size = size(bootFitParams) ;
for iPhenotype=24:35
    for iFreq = 1:2
        for thisMaskCondition = 2:2
            for iBoot = 1:bf_size(4); 
                fprintf(fID,'%s, %0.5e, %s \n',  harmonicNames{iFreq},  bootFitParams(iPhenotype,thisMaskCondition,iFreq,iBoot,1),fittedNames{iPhenotype});
            end %iBoot
        end % mask
    end % iFreq
end %iPhen

%quit
