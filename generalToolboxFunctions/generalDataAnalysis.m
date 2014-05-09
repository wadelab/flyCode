clear all;
close all;

load('test_20140509T090334_AnalysisData_ noNorm.mat'); % This is the file you got from the directory analysis script. It will place a structure calles 'analysisStruct' in the workspace
% ** Obviously you replace the filename above with the one that you saved
% out from the selectLoadAnalyze... script' Or make the call above a
% uigetfile to browse .

% We are about to fit all the 1F1 and 2F1 data with a hyperbolic ratio function...
fComponentList=[1 3];
nPhenotypes=length(analysisStruct.allFlyDataCoh);
for thisPhenotype=1:nPhenotypes
    for thisFComponentIndex=1:2
        for thisMaskType=1:2
            %% Loop over all fly types
            disp('Fitting');
            tic
            thisPhenotypeMeanData=squeeze(mean(analysisStruct.allFlyDataCoh{thisPhenotype},1));
            
            [fittedCRFParams(thisPhenotype,thisFComponentIndex,thisMaskType,:)]=fly_fitHyperData(analysisStruct.params,analysisStruct.contRange,squeeze(abs(thisPhenotypeMeanData(fComponentList(thisFComponentIndex),:,thisMaskType)))); % In fact inc or coh data are the same in this case since the fitting is done on magnitude
            % The fitted params are Rmax, c50, n, R0 (which is fixed at 0)
            toc
        end % Next mask type
    end % Next Freq component
end % Next phenotype

%% As an example, take a look at the 1F1 Rmax parameter across phenotypes for
% masked and unmasked

RmaxParam=squeeze(fittedCRFParams(:,1,:,1))
figure(1);
bar(RmaxParam);
legend({'Unmasked','Masked'});
set(gca,'XTickLabel',analysisStruct.phenotypeName);
title('1F1 masked and unmasked Rmax');

% Here's another example - look at the 2F1 Rmax...
RmaxParam=squeeze(fittedCRFParams(:,2,:,1))
figure(2);
bar(RmaxParam);
legend({'Unmasked','Masked'});
set(gca,'XTickLabel',analysisStruct.phenotypeName);
title('2F1 masked and unmasked Rmax');

% And here we can look at a different parameter: The c50 for the 2F1
c50=squeeze(fittedCRFParams(:,2,:,2))
figure(3);
bar(c50);
legend({'Unmasked','Masked'});
set(gca,'XTickLabel',analysisStruct.phenotypeName);
title('2F1 masked and unmasked c50');

%% Here we show how to plot fitted curves on top of the actual data. We'll
% plot the 1F1 data first

plotColors=[0 0 0;1 0 0]; % Black and red (RGB) values determine the line colors for masked and unmasked
frequencyComponent=1;
lineContrasts=linspace(0,max(analysisStruct.contRange),100); % This is the range of contrasts for which we will plot the fitted lines.

% Here we extract all the Rmax vals so that we know how to scale each yAxis
% in the same way
allRmaxParams=(fittedCRFParams(:,frequencyComponent,:,1));
maxRmaxLevel=max(allRmaxParams(:));

% Make one plot per phenotype
for thisPhenotype=1:nPhenotypes
    figure(4);
    subplot(nPhenotypes,1,thisPhenotype);
    
    hold off;
    for thisMaskType=1:2
        thisPhenotypeMeanData=squeeze(mean(analysisStruct.allFlyDataCoh{thisPhenotype},1));
        dataPointsToPlot=squeeze(abs(thisPhenotypeMeanData(fComponentList(frequencyComponent),:,thisMaskType)));
        dataHandles=plot(analysisStruct.contRange,dataPointsToPlot,'o');
        set(dataHandles,'Color',plotColors(thisMaskType,:));
        
        hold on; % Keep those point that we just plotted and overlay the fitted line
        parameters=fittedCRFParams(thisPhenotype,frequencyComponent,thisMaskType,:);
        fitHandle=plot(lineContrasts,hyper_ratio(parameters,lineContrasts));
        set(fitHandle,'Color',plotColors(thisMaskType,:));
        grid on;
        set(gca,'XScale','Log');
        xlabel('Contrast');
        ylabel('1F1 response');
        set(gca,'XLim',[0.02 1]);
        set(gca,'YLim',[0 maxRmaxLevel]);
        set(fitHandle,'LineWidth',2);
    end
end
set(gcf,'Name','1F1 fits');






%% Here.... we do the bootstrapping. It's not for the faint of heart: It can take quite a while....
%% ***************** THIS IS AS SEPARATE
tic
if(matlabpool('size') ~=0   ) 
    matlabpool('open',4);
end

options=statset('UseParallel','always');
toc
disp('Assigned matlabpool - remember to close it later!');


% Bootstrap RMax, c50,for 2F1 data...
% Make one plot per phenotype
nBootstraps=300;

for thisPhenotype=1:nPhenotypes
    
    for thisMaskType=1:2
        
        thisFlyData=analysisStruct.allFlyDataCoh{thisPhenotype};
        
        dataToFit=(squeeze(thisFlyData(:,fComponentList(frequencyComponent),:,thisMaskType)));
        contrasts=analysisStruct.contRange;
        fprintf('\n%d phenotype',thisPhenotype);
        
        
        tic
        [confInt(thisPhenotype,thisMaskType,frequencyComponent,:,:),bootFitParams(thisPhenotype,thisMaskType,frequencyComponent,:,:)]=bootci(nBootstraps,{@fit_hyper_ratioNoErrMean,squeeze(dataToFit),5,0},'Options',options,'alpha',0.05);%,'type','cper');
        toc
        
      end
    
end

matlabpool close % This command is very mportant. Once you've opened the 'matlab pool' you are controlling all the cores in your CPU. You cannot re-open the matlab pool until you close it...

%% ****************************
% We now have some lovely bootstrapped parameters for all mask conditions
% and all phenotypes. We can plot these in boxplots like this:
figure(10);
for thisMaskCondition=1:2
subplot(2,1,thisMaskCondition);
dataToBoxplot=squeeze(bootFitParams(:,thisMaskCondition,frequencyComponent,:,1))';

boxplot(dataToBoxplot,'notch','on','plotstyle','compact'); % The Rmax fits for both mask and unmasked
grid on;
end
set(gcf,'Name','Rmax unmasked and masked');
%%
% And we can look at the raw histograms like this:
figure(15);
histDataToPlot=squeeze(bootFitParams(1,:,1,:,1));
hist(histDataToPlot',20);
xlabel('Rmax - 1F1 - Phenotype 1');
ylabel('Frequency');

legend({'Unmasked','Masked'});



%% Finally, we can do real statistics on these data using ANOVAs. Let's take a look at a simple 1-way ANOVA on the Rmax of the unmasked 1F1 response
dataToAnalyze=squeeze(bootFitParams(:,1,frequencyComponent,:,1))'; % This will be nPhenotypes x nBootstrap samples. e.g. 5 x 300
conditionCodes=kron((1:nPhenotypes)',ones(nBootstraps,1));

[p1,a1,s1]=anova1(dataToAnalyze(:),conditionCodes);


 % Multcompare is a nice way to look at these data:
 comparison=multcompare(s1);
 
%.. here's the same trick doing a 2xway ANOVA on the 1F1 data looking for
%   an effect of the mask as well as the phenotype
dataToAnalyze=squeeze(bootFitParams(:,:,frequencyComponent,:,1)); % This will be nPhenotypes x nBootstrap samples. e.g. 5 x 300
% We have to shift the dimensions around a bit to get them ready ...
dataToAnalyze=shiftdim(dataToAnalyze,1);
factorCodes1=repmat([1;2],nPhenotypes*nBootstraps,1);
factorCodes2=kron((1:nPhenotypes)',ones(nBootstraps*2,1));

[p,t,stats,terms]=anovan(dataToAnalyze(:),{factorCodes1,factorCodes2});


