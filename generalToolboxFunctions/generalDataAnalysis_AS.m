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
% Now editing to run with Oscar Solis' data (NatSci 2023/24 project with
% Ines and Alex)


clear all;
close all;

nBootstraps=1000;
fToExamine=48; % Change this depending on which harmonic you want. Over 1 second it would be 12 (or 15) - those are the 1F. For 2F you can look at 96,120 cycle
close all

%dataDir='c:\Users\wade\Documents\flyData2022\orgData\';
%dataDir='/Volumes/GoogleDrive/My Drive/York/Projects/InesFly/flyData2022/orgData/';

%dataDir='/groups/labs/wadelab/data/SITRAN/flyData/flyArduino2/FromHardDrive290524';
%inputDirList={  'Pink1B9_1dpe' , 'Pink1B9_3dpe', 'Pink1B9_5dpe', 'Pink1B9_7dpe','Pink1B9_10dpe','Pink1B9_14dpe','Pink1B9_21dpe','Pink1B9_28dpe' };  % This is a list of directories where you have saved the data specific to each genotype. For these will depend on your project
dataDir='/Users/abbiestretch/Documents/PhD/Vision';

%inputDirList={  'DJ1beta_1dpe' , 'DJ1beta_3dpe', 'DJ1beta_5dpe', 'DJ1beta_7dpe','DJ1beta_10dpe','DJ1beta_14dpe','DJ1beta_21dpe','DJ1beta_28dpe' };  % This is a list of directories where you have saved the data specific to each genotype. For these will depend on your project
%inputDirList={  'DJ1alpha_1dpe' , 'DJ1alpha_3dpe', 'DJ1alpha_5dpe', 'DJ1alpha_7dpe','DJ1alpha_10dpe','DJ1alpha_14dpe','DJ1alpha_21dpe','DJ1alpha_28dpe' };
%inputDirList={  'W1118CS_1dpe' , 'W1118CS_3dpe', 'W1118CS_5dpe', 'W1118CS_7dpe','W1118CS_10dpe','W1118CS_14dpe','W1118CS_21dpe','W1118CS_28dpe' };
%inputDirList={'DJ1alpha_1dpe','DJ1beta_1dpe','W1118CS_1dpe'}
%inputDirList={'DJ1alpha_3dpe','DJ1beta_3dpe','W1118CS_3dpe'}
%inputDirList={'DJ1alpha_5dpe','DJ1beta_5dpe','W1118CS_5dpe'}
%inputDirList={'DJ1alpha_7dpe','DJ1beta_7dpe','W1118CS_7dpe'}
%inputDirList={'DJ1alpha_10dpe','DJ1beta_10dpe','W1118CS_10dpe'}
%inputDirList={'DJ1alpha_14dpe','DJ1beta_14dpe','W1118CS_14dpe'}
%inputDirList={'DJ1alpha_21dpe','DJ1beta_21dpe','W1118CS_21dpe'}
%inputDirList={'DJ1alpha_28dpe','DJ1beta_28dpe','W1118CS_28dpe'}

%inputDirList={  'Pink15_1dpe' , 'Pink15_3dpe', 'Pink15_5dpe', 'Pink15_7dpe','Pink15_10dpe','Pink15_14dpe','Pink15_21dpe' };
%inputDirList={  'Pink1B9_1dpe' , 'Pink1B9_3dpe', 'Pink1B9_5dpe', 'Pink1B9_7dpe','Pink1B9_10dpe','Pink1B9_14dpe','Pink1B9_21dpe','Pink1B9_28dpe' };
<<<<<<< HEAD
%inputDirList={  'W1118CSfem_1dpe' , 'W1118CSfem_3dpe', 'W1118CSfem_5dpe', 'W1118CSfem_7dpe','W1118CSfem_10dpe','W1118CSfem_14dpe','W1118CSfem_21dpe' };
 inputDirList={'Pink15_1dpe','Pink1B9_1dpe','W1118CSfem_1dpe'}
=======
%inputDirList={  'W1118CSfem_1dpe' , 'W1118CSfem_3dpe', 'W1118CSfem_5dpe', 'W1118CSfem_7dpe','W1118CSfem_10dpe','W1118CSfem_14dpe','W1118CSfem_21dpe','W1118CSfem_28dpe' };
%inputDirList={'Pink15_1dpe','Pink1B9_1dpe','W1118CSfem_1dpe'}
>>>>>>> parent of 381f340 (Update generalDataAnalysis_AS.m)
%inputDirList={'Pink15_3dpe','Pink1B9_3dpe','W1118CSfem_3dpe'}
%inputDirList={'Pink15_5dpe','Pink1B9_5dpe','W1118CSfem_5dpe'}
inputDirList={'Pink15_7dpe','Pink1B9_7dpe','W1118CSfem_7dpe'}
%inputDirList={'Pink15_10dpe','Pink1B9_10dpe','W1118CSfem_10dpe'}
%inputDirList={'Pink15_14dpe','Pink1B9_14dpe','W1118CSfem_14dpe'}
%inputDirList={'Pink15_21dpe','Pink1B9_21dpe','W1118CSfem_21dpe'}
%inputDirList={'Pink15_28dpe','Pink1B9_28dpe','W1118CSfem_28dpe'}

%inputDirList={  'Pink15_1dpe' , 'Pink1B9_1dpe', 'W1118CSfem_1dpe', 'Pink15_3dpe','Pink1B9_3dpe', 'W1118CSfem_3dpe', 'Pink15_5dpe', 'Pink1B9_5dpe', 'W1118CSfem_5dpe','Pink15_7dpe','Pink1B9_7dpe', 'W1118CSfem_7dpe','Pink15_10dpe', 'Pink1B9_10dpe', 'W1118CSfem_10dpe','Pink15_14dpe', 'Pink1B9_14dpe', 'W1118CSfem_14dpe','Pink15_21dpe', 'Pink1B9_21dpe', 'W1118CSfem_21dpe', 'Pink15_28dpe', 'Pink1B9_28dpe', 'W1118CSfem_28dpe', };

nGT=length(inputDirList);
lineColArray=jet(nGT)

for thisGT=1:nGT
    fInputDir=fullfile(dataDir,inputDirList{thisGT})
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
% For the Stretch dataset F1 is held in data{thisGT}.{thisFly}.F1
% ...and similarlly F2 (the mask) is data{thisGT}.{thisFly}.F2

fComponentList=[1 2];
paramNameList={'Rmax','c50','n','R0'};
%%
for thisGT=1:nGT % Loop over all genotypes. (I know - sometimes the GT is the same and something else has changed like age
    thisGTData=outData{thisGT};
    nFlies=length(thisGTData);
    fprintf('There are %d flies in genotype %d',nFlies,thisGT);

    F1Freq=thisGTData{1}.F1; % all the runs should be the same so pick F1 and F2 from the first one
    F2Freq=thisGTData{1}.F2;

    % Each fly had 9 conditions (in Abi's dataset): 5 contrasts
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
            parpool('local'); % Open 8 threads. If your computer has more than 4 cores then you can get even better performance. I think GPUs are supported these days so with the right hardware you might be able to get x100 speedup!
        end

        options=statset('UseParallel','always'); % Assume you opened up the pool - tell the stats routines to use parallel functions
        
        disp('Assigned matlabpool - remember to close it later!');
    else
        options = statset('UseParallel',0);
        disp('Not using parallel execution - consider installing the Matlab parallel computing toolbox');
    end

    tic
    [confInt(thisGT,:,:),bootFitParams(thisGT,:,:)]=bootci(nBootstraps,{@fit_hyper_ratioNoErrMeanAbbie,squeeze(dataToFit),2,0},'Options',options,'alpha',0.05);%,'type','cper');
    toc

    popMeanAverage{thisGT}=squeeze(mean(meanTS{thisGT}));
    ftPopMeanAverage{thisGT}=fft(popMeanAverage{thisGT},[],2); % Compute the fft down time
    figure(1);
    subplot(nGT,1,thisGT);
    fED=((squeeze(ftPopMeanAverage{thisGT}(4,1:1000))));
    bar(abs(fED(1:130)))

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
    set(gca,'XScale','Log');
end
l=legend(inputDirList)
set(l,'FontSize',14)

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
    f=bar(x+.0025*thisGT,h1(:,thisGT),.8)
    set(f,'FaceColor',lineColArray(thisGT,:))
    set(f,'EdgeColor',lineColArray(thisGT,:))

    set(f,'FaceAlpha',.6)
    hold on;
end
l=legend(inputDirList)
set(l,'FontSize',14)

title('c50')
subplot(2,1,2);
hold off;
h2=hist(squeeze(a(:,:,1)'),40);
for thisGT=1:nGT
    f=bar(x+.0025*thisGT,h2(:,thisGT),.8)
    set(f,'FaceColor',lineColArray(thisGT,:))
        set(f,'EdgeColor',lineColArray(thisGT,:))

    set(f,'FaceAlpha',.6)
    hold on;
end
l=legend(inputDirList)
title('Rmax')
set(l,'FontSize',14)

    


%%
% Also make boxplots to visualise significance more easily

figure(12)
for thisParam=1:2
    subplot(2,1,thisParam);
    boxplot(squeeze(a(:,:,thisParam))','notch','on','outliersize',.001);
    title(paramNameList{thisParam})
    set(gca,'XTickLabel',inputDirList)
end


