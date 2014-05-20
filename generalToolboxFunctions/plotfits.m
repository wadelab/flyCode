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

harmonicNames = {'1F1','1F2';'2F1','2F2'};

%% Plot Rmax ...
for iFreqComponent =1:2
    %  We can plot these in boxplots like this:
    figure;
    
    for thisMaskCondition=1:2
        sPlot = subplot(2,1,thisMaskCondition);
        dataToBoxplot=squeeze(bootFitParams(:,thisMaskCondition,iFreqComponent,:,1))';
        
        boxplot(dataToBoxplot,'notch','on','labels', fittedNames); % The Rmax fits for both mask and unmasked
        %%If you have lots of data, you get a smaller plot...
        %boxplot(dataToBoxplot,'notch','on','plotstyle','compact','labels', fittedNames);
        
    end
    sTmp = strcat('Rmax unmasked and masked ', harmonicNames(iFreqComponent,1));
    set(gcf,'Name',char(sTmp)); %% ] 1F1');
    %%
end ;

%% Do the same for c50

for iFreqComponent =1:2
    %  We can plot these in boxplots like this:
    figure;
    
    for thisMaskCondition=1:2
        sPlot = subplot(2,1,thisMaskCondition);
        dataToBoxplot=squeeze(bootFitParams(:,thisMaskCondition,iFreqComponent,:,2))';
        
        boxplot(dataToBoxplot,'colors','m','notch','on','labels', fittedNames); % The Rmax fits for both mask and unmasked
        %%If you have lots of data, you get a smaller plot... by adding 'plotstyle','compact',
        ymax = get(gca,'YLim');
        set(gca,'YLim', [0,ymax(1,2)]);
    end
    sTmp = strcat('c50 unmasked and masked ', harmonicNames(iFreqComponent,1));
    set(gcf,'Name',char(sTmp)); %% ] 1F1');
    %%
end ;



%%
% And we can look at the raw histograms like this:
%% 
for iFreqComponent =1:2
    for iPhenotypes = 1:length(fittedNames)
        figure;
        histDataToPlot=squeeze(bootFitParams(iPhenotypes,:,iFreqComponent,:,1));
        hist(histDataToPlot',20);
        xlabel(['Rmax -', harmonicNames(iFreqComponent,1) ,'- Phenotype: ', fittedNames{iPhenotypes}]);
        ylabel('Frequency');
        
        legend({'Unmasked','Masked'});
    end
end


%% Finally, we can do real statistics on these data using ANOVAs. Let's take a look at a simple 1-way ANOVA on the Rmax of the unmasked 2F1 response

for iFreqComponent = 1:2;
    figure ;
    dataToAnalyze=squeeze(bootFitParams(:,1,iFreqComponent,:,1))'; % This will be nPhenotypes x nBootstrap samples. e.g. 5 x 300
    conditionCodes=kron((1:maxPhenotypesToPlot)',ones(nBootstraps,1));
    
    [p1,a1,s1]=anova1(dataToAnalyze(:),conditionCodes)
    set(gcf,'Name','Anova: Rmax of the unmasked 1F1');
    
    % Multcompare is a nice way to look at these data:
    comparison=multcompare(s1);
    set(gcf,'Name',char(strcat('Rmax of the unmasked', harmonicNames(iFreqComponent,1))));
    set(gca,'YTickLabel',fliplr(fittedNames));
end ;
%% 
% frequencyComponent  %% should be 2 
% %.. here's the same trick doing a 2xway ANOVA on the 2F1 data looking for
% %   an effect of the mask as well as the phenotype
% dataToAnalyze=squeeze(bootFitParams(:,:,frequencyComponent,:,1)); % This will be nPhenotypes x nBootstrap samples. e.g. 5 x 300
% % We have to shift the dimensions around a bit to get them ready ...
% dataToAnalyze=shiftdim(dataToAnalyze,1);
% factorCodes1=repmat([1;2],maxPhenotypesToPlot*nBootstraps,1);
% factorCodes2=kron((1:maxPhenotypesToPlot)',ones(nBootstraps*2,1));
% 
% [p,t,stats,terms]=anovan(dataToAnalyze(:),{factorCodes1,factorCodes2}, 'varnames',{'mask' 'phenotype'})
% set(gcf,'Name','Rmax of 2f2, with/without mask');

