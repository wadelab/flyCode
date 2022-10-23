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
% Here editing to run with Ines data: 06/10/22

clear all;
close all;
lineColArray=[0.7, 0.1, 0.1; .1, .7, .1; 0.1,.1,.7];

nBootstraps=1000;
fToExamine=48;
close all
%dataDir='c:\Users\wade\Documents\flyData2022\orgData\';
dataDir='/Volumes/GoogleDrive/My Drive/York/Projects/InesFly/flyData2022/orgData/';

inputDirList={'CA','DN','elavssg'};

nGT=length(inputDirList);
for thisGT=1:nGT
    fInputDir=fullfile(dataDir,inputDirList{thisGT});
    offset=thisGT*2-1;
    [outData{thisGT}, successArray]=arw_read_arduino_dir(fInputDir,0);
end

% outData is a cell array of cell arrays. Each sub-cell looks like this
% outData{1}{1}
%                     Error: 'None'
%                  fileName: 'filename=22_21_07_15h17m42_CA ↵'
%                        F1: 12
%                        F2: 15
%                phenotypes: {''  'GAL4=elav'  'UAS=sggCA'  'Age=7'  'sex=male'  'org=tet'  'col=blue'  'bri=255'  'Disco=N'  'stim=SSVEP'}
%           sortedContrasts: [45×3 double]
%             sortedRawData: [45×1024 double]
%            sortedStimData: [45×1024 double]
%     sortedComplex_FFTdata: [45×1000 double]
%                   meanFFT: [9×240 double]
%             meanContrasts: [9×3 double]
%
%

% We are about to fit all the 1F1 and 2F1 data with a hyperbolic ratio function...
% For the Ines dataset F1 is held in data{thisGT}.{thisFly}.F1
% ...and similarlly F2 (the mask) is data{thisGT}.{thisFly}.F2

fComponentList=[1 2];
paramNameList={'Rmax','c50','n','R0'};
%%
for thisGT=1:nGT % Loop over all genotypes. (I know - sometimes the GT is the same and something else has changed like disco...._
    thisGTData=outData{thisGT};
    nFlies=length(thisGTData);
    fprintf('There are %d flies in genotype %d',nFlies,thisGT);

    F1Freq=thisGTData{1}.F1; % all the runs should be the same so pick F1 and F2 from the first one
    F2Freq=thisGTData{1}.F2;

    % Each fly had 9 conditions (in Ines' dataset): 5 contrasts
    % for F1 without the Mask (5,10,30,70,100) and 4 >with< the
    % mask (5,10,30,70)
    % There were also 5 reps (we can work this out because
    % we know the number of contrasts from the meanContrasts
    % and the number of raw trials from, say, sortedRawData
    % The 'sorting' that has happened for the raw trials
    % bunches trials of the same contrast. So all the 5,0s then
    % all the 10,0 then all the 30,0...

    % We ultimately want to load all of these into a single array
    % (for the bootstrapping)
    % For now we could just proceed by fitting functions to
    % averages from each fly: We fit four functions for each
    % fly: response to unmasked and masked data x (1F1 and
    % 2F1)

    % Loop over all flies in a single GT

    for thisFly=1:nFlies

        disp('Computing average');
        thisFlyData=thisGTData{thisFly};
        rawData=thisFlyData.sortedRawData;
        nConts=size(thisFlyData.meanContrasts,1); % How many separate contrast conditions

        [nTrials,nPoints]=size(rawData);

        if(mod(nTrials,nConts)~=0) % Make sure we have the same number of repeats for each condition
            fprintf('Should have the same integer number of repeats for each condition (nTrials=%d, nConts=%d',nTrials,nConts);
            error
        end

        nAvs=nTrials/nConts;

        % reshape and average in the complex domain
        rawReshaped=reshape(rawData,[nAvs,nConts,nPoints]); % reshaped ready for average
        meanRaw=squeeze(mean(rawReshaped(:,:,1:1000)));

        meanTS{thisGT}(thisFly,:,:)=meanRaw; % Mean across all reps for this fly
        meanFT{thisGT}(thisFly,:,:)=fft(meanRaw,[],2);

    end % next fly
end % Next GT
%%
for thisGT=1:nGT
    % Okay now we can bootstrap. For now, I think just consider
    % 2F1 which is both robust and a marker of pure neural
    % function (maybe)
    dataToFit=meanFT{thisGT}(:,1:5,fToExamine+1);
    %dataToFit=(squeeze(thisFlyData(:,fComponentList(thisFrequencyComponentIndex),:,thisMaskType)));                 contrasts=analysisStruct.contRange;
    fprintf('\n%d phenotype\n',thisGT);
    contLevels=thisFlyData.meanContrasts(1:5,2);
    if ( exist('parpool')) ; %%,'builtin')) % Check for the existence of the Parallel computing matlabpool function
        poolobj = gcp('nocreate'); % If no pool, do not create new one.
        if isempty(poolobj)
            poolsize = 0;
        else
            poolsize = poolobj.NumWorkers
        end
        if(poolsize ==0   )
            parpool('local',8); % Open 8 cores. If your computer has more than 4 cores then you can get even better performance. I think GPUs are supported these days so with the right hardware you might be able to get x100 speedup!
        end

        options=statset('UseParallel','always'); % Assume you opened up the pool - tell the stats routines to use parallel functions
        toc
        disp('Assigned matlabpool - remember to close it later!');
    else
        options = statset('UseParallel',0);
        disp('Not using parallel execution - consider installing the Matlab parallel computing toolbox');
    end

    tic
    [confInt(thisGT,:,:),bootFitParams(thisGT,:,:)]=bootci(nBootstraps,{@fit_hyper_ratioNoErrMeanInes,squeeze(dataToFit),2,0},'Options',options,'alpha',0.05);%,'type','cper');
    toc

    popMeanAverage{thisGT}=squeeze(mean(meanTS{thisGT}));
    ftPopMeanAverage{thisGT}=fft(popMeanAverage{thisGT},[],2); % Compute the fft down time
    figure(1);
    subplot(nGT,1,thisGT);
    fED=((squeeze(ftPopMeanAverage{thisGT}(4,1:1000))));
    bar(abs(fED(1:100)))

    % Each trial is 4s worth of data. So the peaks we care
    % about are at 4xF1, 8F1, 4F2, 8F2 and some IM
    keyPeakIndices=[F1Freq, F2Freq, F1Freq*2,F2Freq*2]*4; % For now don't account for the 1 offset in the FFT
    F1ResponseGT=[ftPopMeanAverage{thisGT}(:,keyPeakIndices(3)+1)]
    figure(2)
    subplot(nGT,1,thisGT);

    bar(abs(F1ResponseGT))
    grid on
end
%%

for thisGT=1:nGT
     % Do nice plotting
     meanParams=squeeze(median(bootFitParams(thisGT,:,:)));
     xVals=logspace(-1.5,1,100);
     yVals(:,thisGT)=hyper_ratio(meanParams,xVals); % compute the line from the median vals
     for thisLine=1:nBootstraps
         yValArray(thisLine,:,thisGT)=hyper_ratio(squeeze(bootFitParams(thisGT,thisLine,:)),xVals);
     end
    figure(5);
    shadedErrorBar(xVals,squeeze(yVals(:,thisGT)),std(squeeze(yValArray(:,:,thisGT))),'lineprops',{'Color',lineColArray(thisGT,:),'markerfacecolor',lineColArray(thisGT,:)});
    grid on
    hold on
    set(gca,"XScale",'Log');

end
legend(inputDirList)
%%
maxY=max(yVals(:));
          figure(4);


     plot(xVals,yVals);
    set(gca,'XScale','Log');
    set(gca,'YLim',[0 maxY]);
    grid on;
%%
a=squeeze(bootFitParams(:,:,1:3));
figure(3);
subplot(2,1,1);
hold off
[h1,x]=hist(squeeze(a(:,:,2)'),40);
for thisGT=1:nGT
    f=bar(x+.25*thisGT,h1(:,thisGT),.25)
    set(f,'FaceColor',lineColArray(thisGT,:))
    set(f,'FaceAlpha',.6)
    hold on;
end
legend(inputDirList)
title('c50')
subplot(2,1,2);
hold off;
h2=hist(squeeze(a(:,:,1)'),40);
for thisGT=1:nGT
    f=bar(x+.25*thisGT,h2(:,thisGT),.25)
    set(f,'FaceColor',lineColArray(thisGT,:))
    set(f,'FaceAlpha',.6)
    hold on;
end
legend(inputDirList)
title('Rmax')
    


%%
error

%
%
%
%
%
%                 thisPhenotypeMeanData=squeeze(mean(abs(analysisStruct.allFlyDataCoh{thisGT}),1));
%
%                 [fittedCRFParams(genotypeIndex,thisFComponentIndex,thisMaskType,:)]=fly_fitHyperData(analysisStruct.params,analysisStruct.contRange,squeeze(abs(thisPhenotypeMeanData(fComponentList(thisFComponentIndex),:,thisMaskType)))); % In fact inc or coh data are the same in this case since the fitting is done on magnitude
%                 tmpName = analysisStruct.phenotypeName{thisGT}
%                 tmpName = strrep (tmpName,'all', '');
%                 tmpName = strrep (tmpName,'_', ' ');
%                 fittedNames{genotypeIndex}= tmpName;
%
%                 % The fitted params are Rmax, c50, n, R0 (which is fixed at 0)
%                 toc
%             end % Next mask type
%         end % Next Freq component
% end % Next phenotype
%
% %% As an example, take a look at the 1F1 Rmax parameter across phenotypes for
% % masked and unmasked
% % The indices into fittedCRFParams are
% % [phenotypeIndex, componentIndex, maskIndex, paramIndex]
%
%
% RmaxParam=squeeze(fittedCRFParams(:,1,:,1))
% figure('Name', '1F1 masked and unmasked Rmax');
% bar(RmaxParam);
% legend({'Unmasked','Masked'});
% set(gca,'XTickLabel',fittedNames);
% title('1F1 masked and unmasked Rmax');
%
% % Here's another example - look at the 2F1 Rmax...
% RmaxParam=squeeze(fittedCRFParams(:,2,:,1))
% figure('Name', '2F1 masked and unmasked Rmax');
% bar(RmaxParam);
% legend({'Unmasked','Masked'});
% set(gca,'XTickLabel',fittedNames);
% title('2F1 masked and unmasked Rmax');
%
% % And here we can look at a different parameter: The c50 for the 1F1
% c50=squeeze(fittedCRFParams(:,1,:,2))
% figure('Name', '1F1 masked and unmasked c50');
% bar(c50);
% legend({'Unmasked','Masked'});
% set(gca,'XTickLabel',fittedNames);
% title('1F1 masked and unmasked c50');
%
% % And here we can look at a different parameter: The c50 for the 2F1
% c50=squeeze(fittedCRFParams(:,2,:,2))
% figure('Name', '2F1 masked and unmasked c50');
% bar(c50);
% legend({'Unmasked','Masked'});
% set(gca,'XTickLabel',fittedNames);
% title('2F1 masked and unmasked c50');
%
% %% Here we show how to plot fitted curves on top of the actual data. We'll
% %  plot the 2F1 data
%
% plotColors=[0 0 0;1 0 0]; % Black and red (RGB) values determine the line colors for masked and unmasked
% lineContrasts=linspace(0,max(analysisStruct.contRange),100); % This is the range of contrasts for which we will plot the fitted lines.
%
% %% plot curve and points for F1 and 2F1
% yLabels={'1F1 response', '2F1 response'};
% for frequencyComponent=1:2
% % Here we extract all the Rmax vals so that we know how to scale each yAxis
% % in the same way
% allRmaxParams=(fittedCRFParams(:,frequencyComponent,:,1));
% maxRmaxLevel=max(allRmaxParams(:));
%
% maxPhenotypesToPlot=genotypeIndex; % We've already worked out which phenotypes to ignore and how many we have left.
% genotypeIndex=0; % Reset this.
% [xwins,ywins] = count_subwins(maxPhenotypesToPlot);
% figure();
% %%
% % Make one plot per phenotype
% for thisGT=1:nPhenotypes
%
%     if (strcmp(analysisStruct.phenotypeName{thisGT},'Photodiode') & (IGNORE_PHOTODIODE_FLAG))
%         disp('Skipping photodiode');
%     else
%         genotypeIndex=genotypeIndex+1;
%
%
%         %% if wehave a lot of windows, this is very cumbersome....
%         subplot(xwins, ywins, genotypeIndex);
%
%         hold off;
%
%         for thisMaskType=1:2
%             thisPhenotypeMeanData=squeeze(mean(analysisStruct.allFlyDataCoh{thisGT},1));
%             dataPointsToPlot=squeeze(abs(thisPhenotypeMeanData(fComponentList(frequencyComponent),:,thisMaskType)));
%             dataHandles=plot(analysisStruct.contRange,dataPointsToPlot,'o');
%             set(dataHandles,'Color',plotColors(thisMaskType,:));
%
%             hold on; % Keep those point that we just plotted and overlay the fitted line
%             parameters=fittedCRFParams(genotypeIndex,frequencyComponent,thisMaskType,:);
%             fitHandle=plot(lineContrasts,hyper_ratio(parameters,lineContrasts));
%             set(fitHandle,'Color',plotColors(thisMaskType,:));
%             grid on;
%             set(gca,'XScale','Log');
%             xlabel('Contrast');
%             ylabel(yLabels(frequencyComponent));
%             set(gca,'XLim',[0.02 1]);
%             set(gca,'YLim',[0 maxRmaxLevel]);
%             set(fitHandle,'LineWidth',2);
%             %%maybe we should only do this once...
%             % remove the underscrores which make it hard to read...
%             tmpName = analysisStruct.phenotypeName{thisGT}
%             tmpName = strrep (tmpName,'all', '');
%             tmpName = strrep (tmpName,'_', ' ');
%             title(tmpName);
%         end % Next mask
%     end % End check for Photodiode
%     %%
% end % Nex subplot / phenotype
% set(gcf,'Name',yLabels{frequencyComponent});
% end
% drawnow ;
%
%
%
%
%
%
% %% Here.... we do the bootstrapping. It's not for the faint of heart: It can take quite a while....
% %% If you install the parallel computing toolbox, it will use all your n cores and take and take 1/n as much time
% % It's really worth doing this!
% tic
% if ( exist('parpool')) ; %%,'builtin')) % Check for the existence of the Parallel computing matlabpool function
%     poolobj = gcp('nocreate'); % If no pool, do not create new one.
%     if isempty(poolobj)
%         poolsize = 0;
%     else
%         poolsize = poolobj.NumWorkers
%     end
%     if(poolsize ==0   )
%         parpool('local',8); % Open 8 cores. If your computer has more than 4 cores then you can get even better performance. I think GPUs are supported these days so with the right hardware you might be able to get x100 speedup!
%     end
%
%     options=statset('UseParallel','always'); % Assume you opened up the pool - tell the stats routines to use parallel functions
%     toc
%     disp('Assigned matlabpool - remember to close it later!');
% else
%     options = statset('UseParallel',0);
%     disp('Not using parallel execution - consider installing the Matlab parallel computing toolbox');
% end
%
%
% % Bootstrap RMax, c50,for 2F1 data...
% % Make one plot per phenotype
% nBootstraps=300;
% genotypeIndex=0;
%
% for thisGT=1:nPhenotypes
%     if (strcmp(analysisStruct.phenotypeName{thisGT},'Photodiode') & (IGNORE_PHOTODIODE_FLAG)) % Are we skipping this phenotype?
%         disp('Skipping photodiode');
%     else
%         genotypeIndex=genotypeIndex+1;
%
%         for thisMaskType=1:2 % Loop over all masks
%
%             for thisFrequencyComponentIndex=1:2 % Do fitting for the 1F1 and 2F1 components
%
%                 thisFlyData=analysisStruct.allFlyDataCoh{thisGT};
%
%                 dataToFit=(squeeze(thisFlyData(:,fComponentList(thisFrequencyComponentIndex),:,thisMaskType)));
%                 contrasts=analysisStruct.contRange;
%                 fprintf('\n%d phenotype\n',thisGT);
%
%
%                 tic
%                 [confInt(genotypeIndex,thisMaskType,thisFrequencyComponentIndex,:,:),bootFitParams(genotypeIndex,thisMaskType,thisFrequencyComponentIndex,:,:)]=bootci(nBootstraps,{@fit_hyper_ratioNoErrMean,squeeze(dataToFit),5,0},'Options',options,'alpha',0.05);%,'type','cper');
%                 toc
%             end % Next frequency comp
%         end % Next mask
%     end % End check on photodiode
%
% end % Next phenotype
% if ( exist('matlabpool','builtin'))
%     matlabpool close % This command is very important. Once you've opened the 'matlab pool' you are controlling all the cores in your CPU. You cannot re-open the matlab pool until you close it...
% end
%
% % We have gone to a lot of trouble to do these fits so save them in a temp
% % file quickly!
% fName= [filebaseName,'fitTemp.mat']
% save (fName);
%
% disp('You may want to run plotfits.m to see more graphs and ANOVAs');
% % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % %% Chop here
% % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % %
% % % %% ****************************
% % % % We now have some lovely bootstrapped parameters for all mask conditions
% % % % % The indices into bootFitParams are
% % % % [phenotypeIndex, maskIndex, frequencyComponentIndex, bootStrapInstance, paramIndex]
% % % % The order of the param indices is the same as above: Rmax, c50, n, R0
% % %
% % % %  We can plot these in boxplots like this:
% % % figure(10);
% % %
% % % for thisMaskCondition=1:2
% % %     subplot(2,1,thisMaskCondition);
% % %     dataToBoxplot=squeeze(bootFitParams(:,thisMaskCondition,1,:,1))';
% % %
% % %     boxplot(dataToBoxplot,'notch','on','plotstyle','compact'); % The Rmax fits for both mask and unmasked
% % %     set(gca,'XTickLabel',[fittedNames]);
% % %     grid on;
% % % end
% % %
% % % set(gcf,'Name','Rmax unmasked and masked 1F1');
% % %
% % % %% Look at 2F1 as well
% % % figure(11);
% % %
% % % for thisMaskCondition=1:2
% % %     subplot(2,1,thisMaskCondition);
% % %     dataToBoxplot=squeeze(bootFitParams(:,thisMaskCondition,2,:,1))';
% % %
% % %     boxplot(dataToBoxplot,'notch','on','plotstyle','compact'); % The Rmax fits for both mask and unmasked
% % %     grid on;
% % % end
% % % set(gcf,'Name','Rmax unmasked and masked 2F1');
% % %
% % %
% % % %% In fact we can loop over both masks and components and plot everything in
% % % % one figure:
% % %
% % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%This is not the right thing to plot - this has
% % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%3 values for each data bar ????
% % % figure(12);
% % % for thisFreqComponentIndex=1:2
% % %
% % %     subplot(2,1,thisFreqComponentIndex);
% % %     dataToBoxplot=squeeze(bootFitParams(:,:,2,:,1));
% % %
% % %     notBoxPlot(dataToBoxplot); % The Rmax fits for both mask and unmasked
% % %     grid on;
% % % end
% % % set(gcf,'Name','Rmax unmasked and masked 2F1');
% % %
% % %
% % %
% % % %%
% % % % And we can look at the raw histograms like this:
% % % figure(15);
% % % histDataToPlot=squeeze(bootFitParams(2,:,2,:,1));
% % % hist(histDataToPlot',20);
% % % xlabel(['Rmax - 2F1 - Phenotype: ', fittedNames{2}]);
% % % ylabel('Frequency');
% % %
% % % legend({'Unmasked','Masked'});
% % %
% % %
% % %
% % % %% Finally, we can do real statistics on these data using ANOVAs. Let's take a look at a simple 1-way ANOVA on the Rmax of the unmasked 1F1 response
% % % dataToAnalyze=squeeze(bootFitParams(:,1,frequencyComponent,:,1))'; % This will be nPhenotypes x nBootstrap samples. e.g. 5 x 300
% % % conditionCodes=kron((1:maxPhenotypesToPlot)',ones(nBootstraps,1));
% % %
% % % [p1,a1,s1]=anova1(dataToAnalyze(:),conditionCodes);
% % % set(gcf,'Name','Anova: Rmax of the unmasked 1F1');
% % %
% % % % Multcompare is a nice way to look at these data:
% % % comparison=multcompare(s1);
% % % set(gcf,'Name','Rmax of the unmasked 1F1');
% % % set(gca,'YTickLabel',fliplr(fittedNames));
% % %
% % % %.. here's the same trick doing a 2xway ANOVA on the 1F1 data looking for
% % % %   an effect of the mask as well as the phenotype
% % % dataToAnalyze=squeeze(bootFitParams(:,:,frequencyComponent,:,1)); % This will be nPhenotypes x nBootstrap samples. e.g. 5 x 300
% % % % We have to shift the dimensions around a bit to get them ready ...
% % % dataToAnalyze=shiftdim(dataToAnalyze,1);
% % % factorCodes1=repmat([1;2],maxPhenotypesToPlot*nBootstraps,1);
% % % factorCodes2=kron((1:maxPhenotypesToPlot)',ones(nBootstraps*2,1));
% % %
% % % [p,t,stats,terms]=anovan(dataToAnalyze(:),{factorCodes1,factorCodes2});
% % %
% % % %Save all...
% % % fName= [b,'fitDone.mat']
% % % save (fName);
%
