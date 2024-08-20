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

%dataDir='c:\Users\wade\Documents\flyData2022\orgData\';
%dataDir='/Volumes/GoogleDrive/My Drive/York/Projects/InesFly/flyData2022/orgData/';

%dataDir='/groups/labs/wadelab/data/SITRAN/flyData/flyArduino2/FromHardDrive290524';
%inputDirList={  'Pink1B9_1dpe' , 'Pink1B9_3dpe', 'Pink1B9_5dpe', 'Pink1B9_7dpe','Pink1B9_10dpe','Pink1B9_14dpe','Pink1B9_21dpe','Pink1B9_28dpe' };  % This is a list of directories where you have saved the data specific to each genotype. For these will depend on your project
%dataDir='/Users/abbiestretch/Documents/PhD/Vision';
dataDir='/Users/abbiestretch/Documents/PhD/Vision';
dataDir='/raid/data/SITRAN/DJ1_data_15_08_24'

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

%inputDirList={  'W1118CSfem_1dpe' , 'W1118CSfem_3dpe', 'W1118CSfem_5dpe', 'W1118CSfem_7dpe','W1118CSfem_10dpe','W1118CSfem_14dpe','W1118CSfem_21dpe' };
 %inputDirList={'Pink15_1dpe','Pink1B9_1dpe','W1118CSfem_1dpe'}
%inputDirList={  'W1118CSfem_1dpe' , 'W1118CSfem_3dpe', 'W1118CSfem_5dpe', 'W1118CSfem_7dpe','W1118CSfem_10dpe','W1118CSfem_14dpe','W1118CSfem_21dpe','W1118CSfem_28dpe' };
%inputDirList={'Pink15_1dpe','Pink1B9_1dpe','W1118CSfem_1dpe'}
%inputDirList={'Pink15_3dpe','Pink1B9_3dpe','W1118CSfem_3dpe'}
%inputDirList={'Pink15_5dpe','Pink1B9_5dpe','W1118CSfem_5dpe'}
%inputDirList={'Pink15_7dpe','Pink1B9_7dpe','W1118CSfem_7dpe'}
%inputDirList={'Pink15_10dpe','Pink1B9_10dpe','W1118CSfem_10dpe'}
%inputDirList={'Pink15_14dpe','Pink1B9_14dpe','W1118CSfem_14dpe'}
%inputDirList={'Pink15_21dpe','Pink1B9_21dpe','W1118CSfem_21dpe'}
%inputDirList={'Pink15_28dpe','Pink1B9_28dpe','W1118CSfem_28dpe'}

%inputDirList={  'Pink15_1dpe' , 'Pink1B9_1dpe', 'W1118CSfem_1dpe', 'Pink15_3dpe','Pink1B9_3dpe', 'W1118CSfem_3dpe', 'Pink15_5dpe', 'Pink1B9_5dpe', 'W1118CSfem_5dpe','Pink15_7dpe','Pink1B9_7dpe', 'W1118CSfem_7dpe','Pink15_10dpe', 'Pink1B9_10dpe', 'W1118CSfem_10dpe','Pink15_14dpe', 'Pink1B9_14dpe', 'W1118CSfem_14dpe','Pink15_21dpe', 'Pink1B9_21dpe', 'W1118CSfem_21dpe', 'Pink15_28dpe', 'Pink1B9_28dpe', 'W1118CSfem_28dpe', };
%inputDirList={  'DJ1alpha_1dpe' , 'DJ1beta_1dpe', 'W1118CS_1dpe', 'DJ1alpha_3dpe',  'DJ1beta_3dpe', 'W1118CS_3dpe','DJ1alpha_5dpe',  'DJ1beta_5dpe', 'W1118CS_5dpe', 'DJ1alpha_7dpe',  'DJ1beta_7dpe', 'W1118CS_7dpe','DJ1alpha_10dpe',  'DJ1beta_10dpe', 'W1118CS_10dpe','DJ1alpha_14dpe',  'DJ1beta_14dpe', 'W1118CS_14dpe','DJ1alpha_21dpe',  'DJ1beta_21dpe', 'W1118CS_21dpe','DJ1alpha_28dpe',  'DJ1beta_28dpe', 'W1118CS_28dpe'};

%inputDirList={  'Pink15_1dpe' , 'Pink1B9_1dpe', 'W1118CSfem_1dpe', 'Pink15_7dpe','Pink1B9_7dpe', 'W1118CSfem_7dpe', 'Pink15_14dpe', 'Pink1B9_14dpe', 'W1118CSfem_14dpe','Pink15_21dpe', 'Pink1B9_21dpe', 'W1118CSfem_21dpe', 'Pink15_28dpe', 'Pink1B9_28dpe', 'W1118CSfem_28dpe', };

% Here with the White flashes

%inputDirList={  'DJ1alpha_1dpe' , 'DJ1beta_1dpe', 'DJ1aDJ1b_1dpe', 'W1118CS_1dpe',  'DJ1alpha_7dpe',  'DJ1beta_7dpe', 'DJ1aDJ1b_7dpe','W1118CS_7dpe','DJ1alpha_14dpe',  'DJ1beta_14dpe', 'DJ1aDJ1b_14dpe', 'W1118CS_14dpe','DJ1alpha_21dpe',  'DJ1beta_21dpe', 'DJ1aDJ1b_21dpe', 'W1118CS_21dpe','DJ1alpha_28dpe',  'DJ1beta_28dpe', 'DJ1aDJ1b_28dpe', 'W1118CS_28dpe'};Freq_1F1=6
NORMALIZE_DATA=0;
COMPUTE_SNR=1;
FREQ_1F1=12;
FREQ_2F1=FREQ_1F1*2;
FREQ_3F1=FREQ_1F1*3;
FREQ_4F1=FREQ_1F1*4;

inputDirList={  'DJ1alpha_1dpe' ,   'DJ1alpha_7dpe', 'DJ1alpha_14dpe', 'DJ1alpha_21dpe','DJ1alpha_28dpe', 'DJ1beta_1dpe', 'DJ1beta_7dpe',  'DJ1beta_14dpe','DJ1beta_21dpe', 'DJ1beta_28dpe',   'DJ1aDJ1b_1dpe','DJ1aDJ1b_7dpe',  'DJ1aDJ1b_14dpe',   'DJ1aDJ1b_21dpe', 'DJ1aDJ1b_28dpe'};

critFreqHz=[FREQ_1F1, FREQ_2F1, FREQ_3F1, FREQ_4F1] ;
fileNameOut='responseWideFormatALLF1_SNR.csv'

nGT=length(inputDirList);
lineColArray=jet(nGT)

outData = cell(nGT, 1);  % Initialize outData

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
% Initialize arrays to store statistics
meanParamsArray = NaN(nGT, length(paramNameList));  % Mean of bootstrap parameters
medianParamsArray = NaN(nGT, length(paramNameList));  % Median of bootstrap parameters
stdParamsArray = NaN(nGT, length(paramNameList));  % Standard deviation of bootstrap parameters
stderrParamsArray = NaN(nGT, length(paramNameList));  % Standard error of bootstrap parameters
nArray = NaN(nGT, 1);  % Sample size for each genotype

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
        if NORMALIZE_DATA
            rawReshaped=zscore(rawReshaped,[],3);
        end

        meanRaw=squeeze(mean(rawReshaped(:,:,1:1000)));
        
        meanTS{thisGT}(thisFly,:,:)=meanRaw; % Mean across all reps for this fly
        meanFT{thisGT}(thisFly,:,:)=fft(meanRaw,[],2);

    end % next fly
end % Next GT

%% Here we could do statistics directly on the raw data (without bootstrapping)
% In an ANOVA for example, we could look for an effect of GT and contrast
% and an interaction
% To do that we need to make the data into the appropriate format for an
% ANOVA
% meanFT is a cell array of nGenotypes cells.
% Each cell contains an array of nFliesxnContitions*nDataPoints
% We are interested in the first 5 (unmasked) conditions corresponding to
% increasing probe contrast
% And we want the 13th entry in the third dimension (corresponding to 2F1)
% 
% Assuming meanFT is already computed, we will now break the data into 
% a format suitable for a repeated-measures ANOVA.
function [genotype, age] = parse_genotype_age(dirName)
    % This function assumes that the genotype name is before the first '_'
    % and the age is the part of the name that ends with 'dpe'.
    
    underscoreIdx = strfind(dirName, '_');
    genotype = dirName(1:underscoreIdx(1)-1);
    
    ageStr = regexp(dirName, '\d+dpe', 'match');
    age = str2double(ageStr{1}(1:end-3));
end

% Variables:
% - Genotype: This factor has levels corresponding to different genotypes.
% - Age: This factor has levels corresponding to different ages (d1, d7, d14, d21, d28).
% - Contrast: This is a repeated measure factor with 5 levels.
% Initialize arrays to store data for ANOVA
genotypeArray = [];
ageArray = [];
contrastArray = [];
flyArray = [];
responseArray = [];
flyOffset=0
for thisGT = 1:nGT
    thisGTData = outData{thisGT};
    nFlies = length(thisGTData);
    
    assert(nFlies==10)
    % Extract genotype and age information
    [genotypeName, age] = parse_genotype_age(inputDirList{thisGT});

    for thisFly = 1:nFlies
        thisFlyData = thisGTData{thisFly};
        meanFTFly = meanFT{thisGT}(thisFly, :, :);
        meanFTFly = squeeze(meanFTFly);

        % We want the 13th entry in the third dimension (corresponding to 2F1)
        targetResponse = abs(meanFTFly(1:5, critFreqHz*4+1)); % Extract the data that we want. If it's a list then we compute the RMS
        if COMPUTE_SNR
            % Estimate noise from +-2 side bins
            for thisCF=1:length(critFreqHz)
                noiseBins=([-5,-4,-3,-2,-1,1,2,3,4,5])+critFreqHz(thisCF)*4+1
                localRMSNoise=sqrt(sum(abs(meanFTFly(1:5,noiseBins).^2)/length(noiseBins),2))
                targetResponse(:,thisCF)=targetResponse(:,thisCF)./localRMSNoise
            end
        end

        if size(targetResponse,2)>1
            targetResponse=sqrt(sum(targetResponse.^2,2)/size(targetResponse,2))
        end

        % Store the data in arrays for ANOVA
        nConditions = length(targetResponse);
        genotypeArray = [genotypeArray; repmat({genotypeName}, nConditions, 1)];
        ageArray = [ageArray; repmat(age, nConditions, 1)];
        contrastArray = [contrastArray; thisFlyData.meanContrasts(1:5, 2)];
        flyArray = [flyArray; repmat(thisFly+flyOffset, nConditions, 1)];
        responseArray = [responseArray; targetResponse];
    end
    flyOffset=flyOffset+10
end
%% Convert the data into a table for ANOVA
anovaTable = table(genotypeArray, ageArray, contrastArray, flyArray, responseArray, ...
                   'VariableNames', {'Genotype', 'Age', 'Contrast', 'Fly', 'Response'});

anovaTable.Genotype = categorical(anovaTable.Genotype);
anovaTable.Age = categorical(anovaTable.Age);
anovaTable.Fly = categorical(anovaTable.Fly);
anovaTable.Contrast = categorical(anovaTable.Contrast);

% Unstack the data to create a wide format
responseMatrix = unstack(anovaTable, 'Response', 'Contrast');

% After unstacking, responseMatrix will have columns named after the unique values in Contrast.
% These column names are simply the levels of Contrast, not prefixed by 'Contrast_'.

% Extract the levels of Contrast (these become column names in responseMatrix)
contrastLevels = categories(anovaTable.Contrast);

% Create the 'WithinDesign' table that specifies the within-subject factor
withinDesign = table(contrastLevels, 'VariableNames', {'Contrast'});

% Construct the model formula using the exact column names in responseMatrix
modelFormula = 'x5,x10,x30,x70,x100~Genotype*Age'

% Fit the repeated-measures model
rm = fitrm(responseMatrix, modelFormula, 'WithinDesign', withinDesign);

% Perform the repeated-measures ANOVA
ranovatbl = ranova(rm);
disp(ranovatbl);


% Get the summary of the full model including between-subject effects
betweenSubjectsEffects = anova(rm);
disp(betweenSubjectsEffects);

%%
% Perform the repeated-measures ANOVA (within-subjects effects)
ranovatbl = ranova(rm);
disp('Repeated-Measures ANOVA Table (Within-Subjects):');
disp(ranovatbl);

% Perform the between-subjects ANOVA (Genotype, Age, and their interaction)
betweenSubjectsEffects = anova(rm);
disp('Between-Subjects Effects:');
disp(betweenSubjectsEffects);

% Optional: Post-hoc comparisons (e.g., for Genotype)
postHocResults = multcompare(rm, 'Genotype');
disp('Post-Hoc Comparisons for Genotype:');
disp(postHocResults);


%%
figure(10);
h1=maineffectsplot(anovaTable.Response,{anovaTable.Contrast, anovaTable.Genotype, anovaTable.Age},'varnames',{'Contrast','Genotype','Age'});
title('Main effects ofContrast, Genotype and Age');
ylabel('Mean Response');
grid on
c=get(h1,'Children')
for t=1:length(c)
    set(c(t),'XGrid','on')
    set(c(t),'YGrid','on')
    %set(c(t),'DataAspectRatio',[1,5000,1])
end





%%
figure(11)
% Corrected interactionplot call
h2=interactionplot(anovaTable.Response,{anovaTable.Contrast, anovaTable.Genotype}); %,'varnames',{'Contrast','Genotype'});
title('Interaction Plot of Contrast and Genotype');
xlabel('Contrast Levels');
ylabel('Mean Response');
c2=get(h2,'Children')

for t=1:length(c2)
    if (isprop(c2(t),'XGrid'))
        set(c2(t),'XGrid','on')
        set(c2(t),'YGrid','on')
    end
end


writetable(responseMatrix,fileNameOut)