%This code reads a 'fit' file of bootstrap parameters and plots the data and then does anova on it

close all;
clear all;

[fileToLoad,pathToLoad]=uigetfile('*fitTemp*.mat','Load fit file');
[pathstr, name, ext] = fileparts(fileToLoad);
b = [pathToLoad,name, '_fitted_',datestr(now,30)];


load(fullfile(pathToLoad,fileToLoad));
%% 
%% ****************************
% We now have some lovely bootstrapped parameters for all mask conditions
% % The indices into bootFitParams are
% [phenotypeIndex, maskIndex, frequencyComponentIndex, bootStrapInstance, paramIndex]
% The order of the param indices is the same as above: Rmax, c50, n, R0


%  We can plot these in boxplots like this:
figure;

for thisMaskCondition=1:2
    sPlot = subplot(2,1,thisMaskCondition);
    dataToBoxplot=squeeze(bootFitParams(:,thisMaskCondition,1,:,1))';
    
    boxplot(dataToBoxplot,'notch','on','labels', fittedNames); % The Rmax fits for both mask and unmasked
    
end

set(gcf,'Name','Rmax unmasked and masked 1F1');
%% 

%% Look at 2F1 as well
figure;

for thisMaskCondition=1:2
    subplot(2,1,thisMaskCondition);
    dataToBoxplot=squeeze(bootFitParams(:,thisMaskCondition,2,:,1))';
    
    boxplot(dataToBoxplot,'notch','on','plotstyle','compact','labels', fittedNames); % The Rmax fits for both mask and unmasked
    grid on;
end
set(gcf,'Name','Rmax unmasked and masked 2F1');


% % % %% In fact we can loop over both masks and components and plot everything in
% % % one figure:
% % 
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%This is not the right thing to plot - this has
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%3 values for each data bar ????
% % figure;
% % for thisFreqComponentIndex=1:2
% %     
% %     subplot(2,1,thisFreqComponentIndex);
% %     dataToBoxplot=squeeze(bootFitParams(:,:,2,:,1));
% %     
% %     notBoxPlot(dataToBoxplot); % The Rmax fits for both mask and unmasked
% %     grid on;
% % end
% % set(gcf,'Name','Rmax unmasked and masked 2F1');



%%
% And we can look at the raw histograms like this:
figure;
histDataToPlot=squeeze(bootFitParams(2,:,2,:,1));
hist(histDataToPlot',20);
xlabel(['Rmax - 2F1 - Phenotype: ', fittedNames{2}]);
ylabel('Frequency');

legend({'Unmasked','Masked'});



%% Finally, we can do real statistics on these data using ANOVAs. Let's take a look at a simple 1-way ANOVA on the Rmax of the unmasked 1F1 response
dataToAnalyze=squeeze(bootFitParams(:,1,frequencyComponent,:,1))'; % This will be nPhenotypes x nBootstrap samples. e.g. 5 x 300
conditionCodes=kron((1:maxPhenotypesToPlot)',ones(nBootstraps,1));

[p1,a1,s1]=anova1(dataToAnalyze(:),conditionCodes);
set(gcf,'Name','Anova: Rmax of the unmasked 1F1');

% Multcompare is a nice way to look at these data:
comparison=multcompare(s1);
set(gcf,'Name','Rmax of the unmasked 1F1');
set(gca,'YTickLabel',fliplr(fittedNames));
%% 

%.. here's the same trick doing a 2xway ANOVA on the 1F1 data looking for
%   an effect of the mask as well as the phenotype
dataToAnalyze=squeeze(bootFitParams(:,:,frequencyComponent,:,1)); % This will be nPhenotypes x nBootstrap samples. e.g. 5 x 300
% We have to shift the dimensions around a bit to get them ready ...
dataToAnalyze=shiftdim(dataToAnalyze,1);
factorCodes1=repmat([1;2],maxPhenotypesToPlot*nBootstraps,1);
factorCodes2=kron((1:maxPhenotypesToPlot)',ones(nBootstraps*2,1));

[p,t,stats,terms]=anovan(dataToAnalyze(:),{factorCodes1,factorCodes2}, 'varnames',{'mask' 'phenotype'});

