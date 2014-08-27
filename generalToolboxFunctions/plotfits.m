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

%% Plot Rmax non parametric version...   
% to get the scale the same in each case... , and allow for headroom multiply by 1.2
    maxRMax = max(max(max(max(squeeze(bootFitParams(:,:,:,:,1)))))) ;
    maxRMax = maxRMax * 1.2 ;

    for iFreqComponent =1:2
    %  We can plot these in boxplots like this:
    figure;
    
    for thisMaskCondition=1:2
        sPlot = subplot(2,1,thisMaskCondition);
        dataToBoxplot=squeeze(bootFitParams(:,thisMaskCondition,iFreqComponent,:,1))';
        
        boxplot(dataToBoxplot,'labelorientation',sStyle,'notch','on','labels', fittedNames); % The Rmax fits for both mask and unmasked
        %%If you have lots of data, you get a smaller plot...
        %boxplot(dataToBoxplot,'notch','on','plotstyle','compact','labels', fittedNames);
        set(gca,'YLim', [0, maxRMax]);
    end
    sTmp = strcat('Rmax median unmasked and masked ', harmonicNames(iFreqComponent,1));
    set(gcf,'Name',char(sTmp)); %% ] 1F1'); 
    %
    %notBoxPlot(dataToBoxplot); errorbar(mean(dataToBoxplot), std(dataToBoxplot));
end ;


%% Plot Rmax mean etc ...   

    for iFreqComponent =1:2
    %  We can plot these in boxplots like this:
    figure;
    
    for thisMaskCondition=1:2
        sPlot = subplot(2,1,thisMaskCondition);
        dataToBoxplot=squeeze(bootFitParams(:,thisMaskCondition,iFreqComponent,:,1))';
        %notBoxPlot(dataToBoxplot); errorbar(mean(dataToBoxplot), std(dataToBoxplot));
        notBoxPlot(dataToBoxplot,xToPlot, 0.8) ;
        set(gca,'XTickLabel',fittedNames);
        rotateXLabels( gca, xAngle );
        set(gca,'YLim', [0, maxRMax]);
    end
    sTmp = strcat('Rmax mean unmasked and masked ', harmonicNames(iFreqComponent,1));
    set(gcf,'Name',char(sTmp)); %% ] 1F1');
    %
    
end ;

%% Do the same for c50
   % to get the scale the same in each case... , and allow for headroom multiply by 1.2
    maxc50 = max(max(max(max(squeeze(bootFitParams(:,:,:,:,2)))))) ;
    maxc50 = maxc50 * 1.2 ;
for iFreqComponent =1:2
    %  We can plot these in boxplots like this:
    figure;
 
    
    for thisMaskCondition=1:2
        sPlot = subplot(2,1,thisMaskCondition);
        dataToBoxplot=squeeze(bootFitParams(:,thisMaskCondition,iFreqComponent,:,2))';
        boxplot(dataToBoxplot,'labelorientation',sStyle,'colors','m','notch','on','labels', fittedNames); % The Rmax fits for both mask and unmasked
       %%If you have lots of data, you get a smaller plot... by adding 'plotstyle','compact',
        %ymax = get(gca,'YLim');
        %set(gca,'YLim', [0,ymax(1,2)]);
        set(gca,'YLim', [0, maxc50]);
    end
    sTmp = strcat('c50 unmasked and masked ', harmonicNames(iFreqComponent,1));
    set(gcf,'Name',char(sTmp)); %% ] 1F1');
    %
end ;

%% Plot c50 mean etc ...   

    for iFreqComponent =1:2
    %  We can plot these in boxplots like this:
    figure;
    
    for thisMaskCondition=1:2
        sPlot = subplot(2,1,thisMaskCondition);
        dataToBoxplot=squeeze(bootFitParams(:,thisMaskCondition,iFreqComponent,:,2))';
        %notBoxPlot(dataToBoxplot); errorbar(mean(dataToBoxplot), std(dataToBoxplot));
        notBoxPlot(dataToBoxplot,xToPlot, 0.8) ;
        set(gca,'XTickLabel',fittedNames);
        rotateXLabels( gca, xAngle );
        set(gca,'YLim', [0, maxc50]);
    end
    sTmp = strcat('c50 mean unmasked and masked ', harmonicNames(iFreqComponent,1));
    set(gcf,'Name',char(sTmp)); %% ] 1F1');
    %
    
end ;

%%
% And we can look at the raw histograms like this:
%% 
for iFreqComponent =1:2
    for iPhenotypes = 1:length(fittedNames)
        figure;
        histDataToPlot=squeeze(bootFitParams(iPhenotypes,:,iFreqComponent,:,1));
        hist(histDataToPlot',20);
        sTmp = strcat('Rmax hist -', harmonicNames(iFreqComponent,1) ,'- Phenotype: ', fittedNames{iPhenotypes})
        xlabel(sTmp);
        ylabel('Frequency');
        %set(gca,'XLim', [0, maxRMax]);
        legend({'Unmasked','Masked'});
        set(gcf,'Name',char(sTmp));
    end
end


%% Finally, we can do real statistics on these data using ANOVAs. First for the RMax
for iFreqComponent = 1:2;
    %figure ; % it does it for us..
    disp (strcat('Anova of Rmax of the unmasked', harmonicNames(iFreqComponent,1)));
    dataToAnalyze=squeeze(bootFitParams(:,1,iFreqComponent,:,1))'; % This will be nPhenotypes x nBootstrap samples. e.g. 5 x 300
    conditionCodes=kron((1:maxPhenotypesToPlot)',ones(nBootstraps,1));
    
    [p1,a1,s1]=anova1(dataToAnalyze(:),conditionCodes)
    set(gcf,'Name',char(strcat('Rmax of the unmasked', harmonicNames(iFreqComponent,1))));
    
    % Multcompare is a nice way to look at these data:
    comparison=multcompare(s1);
    set(gcf,'Name',char(strcat('Rmax of the unmasked', harmonicNames(iFreqComponent,1))));
    set(gca,'YTickLabel',fliplr(fittedNames));
end ;

%% Now for the c50
for iFreqComponent = 1:2;
    %figure ;
    disp (strcat('Anova of c50 of the unmasked', harmonicNames(iFreqComponent,1)))
    
    dataToAnalyze=squeeze(bootFitParams(:,1,iFreqComponent,:,2))'; % This will be nPhenotypes x nBootstrap samples. e.g. 5 x 300
    conditionCodes=kron((1:maxPhenotypesToPlot)',ones(nBootstraps,1));
    
    [p1,a1,s1]=anova1(dataToAnalyze(:),conditionCodes)
    set(gcf,'Name',char(strcat('c50 of the unmasked', harmonicNames(iFreqComponent,1))));
    
    % Multcompare is a nice way to look at these data:
    comparison=multcompare(s1);
    set(gcf,'Name',char(strcat('c50 of the unmasked', harmonicNames(iFreqComponent,1))));
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

