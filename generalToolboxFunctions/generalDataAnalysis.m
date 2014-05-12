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

[fileToLoad,pathToLoad]=uigetfile('*analysis*.mat','Load analysis file');

load(fullfile(pathToLoad,fileToLoad)); % This is the file you got from the directory analysis script. It will place a structure calles 'analysisStruct' in the workspace
% ** Obviously you replace the filename above with the one that you saved
% out from the selectLoadAnalyze... script' Or make the call above a
% uigetfile to browse .

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
                fittedNames{phenotypeIndex}=analysisStruct.phenotypeName{thisPhenotype};
                
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
figure(1);
bar(RmaxParam);
legend({'Unmasked','Masked'});
set(gca,'XTickLabel',fittedNames);
title('1F1 masked and unmasked Rmax');

% Here's another example - look at the 2F1 Rmax...
RmaxParam=squeeze(fittedCRFParams(:,2,:,1))
figure(2);
bar(RmaxParam);
legend({'Unmasked','Masked'});
set(gca,'XTickLabel',fittedNames);
title('2F1 masked and unmasked Rmax');

% And here we can look at a different parameter: The c50 for the 2F1
c50=squeeze(fittedCRFParams(:,2,:,2))
figure(3);
bar(c50);
legend({'Unmasked','Masked'});
set(gca,'XTickLabel',fittedNames);
title('2F1 masked and unmasked c50');

%% Here we show how to plot fitted curves on top of the actual data. We'll
%  plot the 2F1 data

plotColors=[0 0 0;1 0 0]; % Black and red (RGB) values determine the line colors for masked and unmasked
frequencyComponent=2;
lineContrasts=linspace(0,max(analysisStruct.contRange),100); % This is the range of contrasts for which we will plot the fitted lines.

% Here we extract all the Rmax vals so that we know how to scale each yAxis
% in the same way
allRmaxParams=(fittedCRFParams(:,frequencyComponent,:,1));
maxRmaxLevel=max(allRmaxParams(:));

maxPhenotypesToPlot=phenotypeIndex; % We've already worked out which phenotypes to ignore and how many we have left.
phenotypeIndex=0; % Reset this.

% Make one plot per phenotype
for thisPhenotype=1:nPhenotypes
    figure(4);
    if (strcmp(analysisStruct.phenotypeName{thisPhenotype},'Photodiode') & (IGNORE_PHOTODIODE_FLAG))
        disp('Skipping photodiode');
    else
        phenotypeIndex=phenotypeIndex+1;
        
        
        
        subplot(maxPhenotypesToPlot,1,phenotypeIndex);
        
        hold off;
        
        for thisMaskType=1:2
            thisPhenotypeMeanData=squeeze(mean(analysisStruct.allFlyDataCoh{thisPhenotype},1));
            dataPointsToPlot=squeeze(abs(thisPhenotypeMeanData(fComponentList(frequencyComponent),:,thisMaskType)));
            dataHandles=plot(analysisStruct.contRange,dataPointsToPlot,'o');
            set(dataHandles,'Color',plotColors(thisMaskType,:));
            
            hold on; % Keep those point that we just plotted and overlay the fitted line
            parameters=fittedCRFParams(phenotypeIndex,frequencyComponent,thisMaskType,:);
            fitHandle=plot(lineContrasts,hyper_ratio(parameters,lineContrasts));
            set(fitHandle,'Color',plotColors(thisMaskType,:));
            grid on;
            set(gca,'XScale','Log');
            xlabel('Contrast');
            ylabel('2F1 response');
            set(gca,'XLim',[0.02 1]);
            set(gca,'YLim',[0 maxRmaxLevel]);
            set(fitHandle,'LineWidth',2);
            title(analysisStruct.phenotypeName{thisPhenotype});
        end % Next mask
    end % End check for Photodiode
end % Nex subplot / phenotype
set(gcf,'Name','2F1 fits');






%% Here.... we do the bootstrapping. It's not for the faint of heart: It can take quite a while....
%% If you install the parallel computing toolbox, it will use all your n cores and take and take 1/n as much time
% It's really worth doing this!
tic
if ( exist('matlabpool','builtin')) % Check for the existence of the Parallel computing matlabpool function
    if(matlabpool('size') ~=0   )
        matlabpool('open',4); % Open four cores. If your computer has more than 4 cores then you can get even better performance. I think GPUs are supported these days so with the right hardware you might be able to get x100 speedup!
    end
    
    options=statset('UseParallel','always'); % Assume you opened up the pool - tell the stats routines to use parallel functions
    toc
    disp('Assigned matlabpool - remember to close it later!');
else
    options = statset('UseParallel',0);
    disp('Not using parallel execution - consider installing the Matlab parallel computing toolbox');
end


% Bootstrap RMax, c50,for 2F1 data...
% Make one plot per phenotype
nBootstraps=300;
phenotypeIndex=0;

for thisPhenotype=1:nPhenotypes
    if (strcmp(analysisStruct.phenotypeName{thisPhenotype},'Photodiode') & (IGNORE_PHOTODIODE_FLAG)) % Are we skipping this phenotype?
        disp('Skipping photodiode');
    else
        phenotypeIndex=phenotypeIndex+1;
        
        for thisMaskType=1:2 % Loop over all masks
            
            for thisFrequencyComponentIndex=1:2 % Do fitting for the 1F1 and 2F1 components
                
                thisFlyData=analysisStruct.allFlyDataCoh{thisPhenotype};
                
                dataToFit=(squeeze(thisFlyData(:,fComponentList(thisFrequencyComponentIndex),:,thisMaskType)));
                contrasts=analysisStruct.contRange;
                fprintf('\n%d phenotype\n',thisPhenotype);
                
                
                tic
                [confInt(phenotypeIndex,thisMaskType,thisFrequencyComponentIndex,:,:),bootFitParams(phenotypeIndex,thisMaskType,thisFrequencyComponentIndex,:,:)]=bootci(nBootstraps,{@fit_hyper_ratioNoErrMean,squeeze(dataToFit),5,0},'Options',options,'alpha',0.05);%,'type','cper');
                toc
            end % Next frequency comp
        end % Next mask
    end % End check on photodiode
    
end % Next phenotype
if ( exist('matlabpool','builtin'))
    matlabpool close % This command is very important. Once you've opened the 'matlab pool' you are controlling all the cores in your CPU. You cannot re-open the matlab pool until you close it...
end

% We have gone to a lot of trouble to do these fits so save them in a temp
% file quickly!
save fitTemp.mat


%% ****************************
% We now have some lovely bootstrapped parameters for all mask conditions
% % The indices into bootFitParams are
% [phenotypeIndex, maskIndex, frequencyComponentIndex, bootStrapInstance, paramIndex]
% The order of the param indices is the same as above: Rmax, c50, n, R0

%  We can plot these in boxplots like this:
figure(10);

for thisMaskCondition=1:2
    subplot(2,1,thisMaskCondition);
    dataToBoxplot=squeeze(bootFitParams(:,thisMaskCondition,1,:,1))';
    
    boxplot(dataToBoxplot,'notch','on','plotstyle','compact'); % The Rmax fits for both mask and unmasked
    grid on;
end
set(gcf,'Name','Rmax unmasked and masked 1F1');

%% Look at 2F1 as well
figure(11);

for thisMaskCondition=1:2
    subplot(2,1,thisMaskCondition);
    dataToBoxplot=squeeze(bootFitParams(:,thisMaskCondition,2,:,1))';
    
    boxplot(dataToBoxplot,'notch','on','plotstyle','compact'); % The Rmax fits for both mask and unmasked
    grid on;
end
set(gcf,'Name','Rmax unmasked and masked 2F1');


%% In fact we can loop over both masks and components and plot everything in
% one figure:
figure(12);
for thisFreqComponentIndex=1:2
    
    subplot(2,1,thisFreqComponentIndex);
    dataToBoxplot=squeeze(bootFitParams(:,:,2,:,1));
    
    notBoxPlot(dataToBoxplot); % The Rmax fits for both mask and unmasked
    grid on;
end
set(gcf,'Name','Rmax unmasked and masked 2F1');



%%
% And we can look at the raw histograms like this:
figure(15);
histDataToPlot=squeeze(bootFitParams(2,:,2,:,1));
hist(histDataToPlot',20);
xlabel('Rmax - 2F1 - Phenotype 2');
ylabel('Frequency');

legend({'Unmasked','Masked'});



%% Finally, we can do real statistics on these data using ANOVAs. Let's take a look at a simple 1-way ANOVA on the Rmax of the unmasked 1F1 response
dataToAnalyze=squeeze(bootFitParams(:,1,frequencyComponent,:,1))'; % This will be nPhenotypes x nBootstrap samples. e.g. 5 x 300
conditionCodes=kron((1:maxPhenotypesToPlot)',ones(nBootstraps,1));

[p1,a1,s1]=anova1(dataToAnalyze(:),conditionCodes);


% Multcompare is a nice way to look at these data:
comparison=multcompare(s1);

%.. here's the same trick doing a 2xway ANOVA on the 1F1 data looking for
%   an effect of the mask as well as the phenotype
dataToAnalyze=squeeze(bootFitParams(:,:,frequencyComponent,:,1)); % This will be nPhenotypes x nBootstrap samples. e.g. 5 x 300
% We have to shift the dimensions around a bit to get them ready ...
dataToAnalyze=shiftdim(dataToAnalyze,1);
factorCodes1=repmat([1;2],maxPhenotypesToPlot*nBootstraps,1);
factorCodes2=kron((1:maxPhenotypesToPlot)',ones(nBootstraps*2,1));

[p,t,stats,terms]=anovan(dataToAnalyze(:),{factorCodes1,factorCodes2});



