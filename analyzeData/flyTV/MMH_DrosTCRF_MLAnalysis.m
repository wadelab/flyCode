% Machine Learning Discriminant Analysis for Temporal Contrast Response
% Functions in Drosopihla PD models study. 
% This code sorts our data and extracts Fourier amplitudes (2nd harmonic) from our ERG data
    % We compute heat maps, a multidimensional space map, N-way class. and
    % pairwise class.
    % We can also do both classifications using bootstrapped data sets

% We input a single directory that contains further directories of each
% Genotype/Phenotype combo we wish to include in the classification
% analysis.

%Let's begin.
close all
clear all

%Get container directory
dataDir = uigetdir;

%List our genotypes, the first two being . and ..
dList = dir(dataDir);
gtIndex = 1;

%% Part 1: Data extraction and Fourier Transform
% Here we resort our data and extract the second harmonic of the FT. Our
% end result is exAmps which contains a cell of data for each of our
% genotypes within the dataDir.

%Ignoring first and second folders as they are . and ..
for thisGeno = 3:length(dList)
    %parse underscore
    gtName{gtIndex}=strrep(dList(thisGeno).name,'_','-');
    
    %Create file list for this genotype
    fList=dir(fullfile(dataDir,dList(thisGeno).name,'*.mat'));
    nFlies=length(fList);
    
    %Now do the extraction
    for thisFly = 1:nFlies
        fName=fullfile(dataDir,dList(thisGeno).name,fList(thisFly).name);
        dataSetName=fullfile(fName);
        thisD=load(dataSetName);
        
        %We need to resort data. It is saved as reps x trials x samples
        %Set these
        [nRepeats,nTrials,nSamples]=size(thisD.data);
        
        %Loop and extract temporal frequency and contrast for all data
        for thisRep = 1:nRepeats
            for thisTrial = 1:nTrials
                trialMetaData = thisD.metaData{thisRep,thisTrial};
                tf(thisRep,thisTrial)=trialMetaData.stim.temporal.frequency(1);%extract temporal frequency
                cont(thisRep,thisTrial)=trialMetaData.stim.cont(1); %extract contrast
                shuffleSeq(thisRep,:)=trialMetaData.shuffleSeq; % Shuffleseq is our randomized presentation index
                
                %Let's sort the data!
                [sSeq,i]=sort(shuffleSeq(thisRep,:)); %Sort our data
            end
            
            %Add it to our data structure
            datStruct(thisFly,thisRep,:,:)=thisD.data(thisRep,:,:);
            tfList(thisFly,thisRep,:)=tf(thisRep,:);
            contList(thisFly,thisRep,:)=cont(thisRep,:);
        end
    end
    
    % We aren't quite done yet. We now have a set of unsorted data for each
    % fly.
    % (nReps * nConditions * nSamples * nSecs) with a corresponding temporal
    % frequency and contrast.
    % We can use 'unique' to assign a x and y index to each condition.
    
    for thisFly = 1:nFlies
        for thisRep =1:nRepeats
            thisContList=contList(thisFly,thisRep,:);
            thisTfList=tfList(thisFly,thisRep,:);
            [uniqueCont,contIndexOut,contIndexIn]=unique(thisContList);
            [uniqueTF,tfIndexOut,tfIndexIn]=unique(thisTfList);
            nTrials=length(tfIndexIn);
            
            %Now create a finalised dataset
            for thisTrial=1:nTrials
                fullDat(thisFly,thisRep,tfIndexIn(thisTrial),contIndexIn(thisTrial),:)=datStruct(thisFly,thisRep,thisTrial,:);
            end
        end
    end
    
    %Let's do some coherent averaging, transient cropping, and plot the
    %time course to check the fly isn't dead.
    
    secsToDump = 1; %dump the onset transient
    durSecs = trialMetaData.stim.temporal.duration;
    secsToKeep = durSecs - secsToDump; %Should be 10s kept
    
    digitizerRate=length(trialMetaData.TimeStamps)/durSecs; %Should be 1000 Hz
    
    %If it isn't 1000 Hz, we are going to make it 1000 Hz.
    if (digitizerRate ~= fix(digitizerRate))
        fprtinf('\nWarning!Non integer digitizer rate %.2d \nSetting to 1000 but beware!\n',digitizerRate);
        digitizerRate=1000;
    end
    
    %fullDat(thisfly, thisRep, tfIndex, contIndex,:)
    %Crop it
    croppedDat=fullDat(:,:,:,:,(secsToDump*digitizerRate+1):(secsToKeep*1000+secsToDump*digitizerRate));

    %Now let's look at some plots, starting off with Fourier transform for
    %just two temporal frequencies, say 6 and 18Hz
    
    egSeq=croppedDat(:,1,[4,7],8,:); %5D Array,
    egSeq=squeeze(egSeq); %remove singularities
    meanSeq=squeeze(mean(egSeq,1)); %takes out the 'all thisfly' as we average
    rsSeq=reshape(meanSeq',1000,10,2); %reshapes meanSeq' into 1000,10,2 as size vector
    overallSeq=squeeze(mean(rsSeq,2)); % Average across all the seconds

    fOverall=fft(overallSeq); %Fourier Transform
    fOverall(1,:)=0; %remove the mean so it plots nicely
    fOverall(48:52,:)=0; %strip out 50Hz amp noise
    fOverall((end-51):(end-48),:)=0;
    reconSeq=real(ifft(fOverall)); %real numbers and FT inverse to get it back

    
    %Plot signal
    figure(1);
    clf;
    subplot(2,1,1);
    c=plot(reconSeq);
    set(c(1),'LineWidth',2);
    set(c(2),'LineWidth',2);
    set(c(1),'Color',[0 0 .4]);
    set(c(2),'Color',[.8 .3 .3]);
    xlabel('Time (ms)');
    set(gca,'YLim',[-.04 .04]);
    ylabel('Amplitude uVe-3');
    legend({'6Hz','18Hz'})
    title('Average signal response for one genotype at 99% contrast and two temporal frequencies')
    
    %Plot amplitudes SOMETHING IS GOING WRONG WITH BARWEB
    subplot(2,1,2);
    fDat=fft(reconSeq)/1000;
%     s=barweb(abs(fDat(2:25,:)),zeros(24,2),.5);
%     s=bar(abs(fDat(2:90,:)),.75);
    xlabel('Temporal frequency (Hz)');
    ylabel('Amplitude uVe-3');
    set(c(1),'LineWidth',2);
    set(c(2),'LineWidth',2);
    set(c(1),'Color',[0 0 .4]);
    set(c(2),'Color',[.8 .3 .3]);
    legend({'6Hz harmonics', '18Hz harmonics'})
    title('Fourier amplitudes for 6Hz and 18Hz, peaks occur at harmonics of input frequencies')

    %I hope they're alive. Now let's compute the final FFT on our cropped
    %data. 
    
    % Compute final FT on cropped data
    ftAcrossReps=(fft(croppedDat,[],5)/(secsToKeep*1000));
    [nFlies,nReps,nTFs,nSFs,nSamps]=size(ftAcrossReps);
    tm=mean(ftAcrossReps,2);
    fMeanAcrossReps=reshape(tm,[nFlies,nTFs,nSFs,nSamps]);
            
    %Now we extract our probed frequencies
    freqsToExtract=(uniqueTF*secsToKeep); %do i need the extra second bit?
    for thisFly=1:nFlies
        for thisTF=1:length(uniqueTF)
            for thisCont=1:length(uniqueCont)
                for thisHarmonic=1:2
                    
                    currF=freqsToExtract(thisTF)*thisHarmonic+1; %Second harmonic
                    extractedAmps(thisFly,thisTF,thisCont,thisHarmonic)=fMeanAcrossReps(thisFly,thisTF,thisCont,currF); %,freqsToExtract(thisTrial));
                    ampPower(thisFly,thisTF,thisCont,thisHarmonic)=sqrt(sum(abs(fMeanAcrossReps(thisFly,thisTF,thisCont,1:50)).^2,4));
                    coh(thisFly,thisTF,thisCont,thisHarmonic)=abs(extractedAmps(thisFly,thisTF,thisCont,thisHarmonic))./ampPower(thisFly,thisTF,thisCont,thisHarmonic);
                end % Next harmonic
            end % Next contrast
        end % Next temporal frequency
    end % Next Fly
    
    % Next, we place all our extracted data into a single cell array. 
    % exAmps will contain our 10 flies x 64 conditions for thisGenotype,
    % thus we will have a cell for each genoype.
 
    exAmps{gtIndex}=extractedAmps;
    ampPow{gtIndex}=ampPower;
    coherence{gtIndex}=coh;
    clear extractedAmps;
    clear ampPower;
    clear coh;
    
    gtIndex=gtIndex+1; %Genotype counter

end %and we're done. Do it all again for the next genotype

disp('Extraction completed');

%% Part 2a: Machine Learning Discriminant Analysis: Create training data
% All the important data have now been placed in extractedAmps - our
% extracted amplitudes. Our goal now is to use machine learning
% discriminant analysis to classify - either N-way or pairwise. Let's do
% N-way first.

%Organise data into a single array with [amp, class] to use as training
%data

nGenotypes=gtIndex-1;
allData=[];
allClass=[];

for thisGT=1:nGenotypes
    thisData=squeeze(exAmps{thisGT}(:,:,:,2));
    
    figure(10);
    subplot(3,2,thisGT);
    mD=squeeze(mean(abs(thisData)));
    
    imagesc(log(mD));
    meanDat(thisGT,:)=mD(:);
    colormap hot;
    c = colorbar;
    caxis([-13, -4.2])
    title(dList(thisGT+2).name);
    ylabel(c, 'F2 amplitude microVolts')
    %axis square
    
   
    [nFlies,nCONT,nTF]=size(thisData);
    reshapedData=reshape(thisData,nFlies,nCONT*nTF);
    classMarker=ones(nFlies,1)*thisGT;
    nFliesInGt(thisGT)=nFlies;
    allData=cat(1,allData,reshapedData); % These are still complex for now.
    allClass=cat(1,allClass,classMarker);
    
    %allData now contains all of the data in a conditionsamplesize x 64
    %array (fliesxconditions x 64)
end
disp('Classification training set is now created')

% Let's plot the 8Hz CRF as this seems to be the peak strip in the heatmaps
% figure(3)
% allConts=unique(contList);
% hold on
% for thisGT=1:nGenotypes
% ctrf = plot(allConts,squeeze(abs(mean(exAmps{thisGT}(:,4,:,2))))','color',rand(1,3)); %2 is the harmonic
% set(ctrf,'linewidth', 3)
% end
% hold off
% set(gca,'box', 'off')
% set(gca,'YScale','Linear');
% set(gca,'YLim',[0 .01]);
% legend
% htitle = get(hleg,'Title');
% set(htitle,'String','Genotype');
% xlabel('Contrast')
% ylabel('Amps')
% title('CRF at 8Hz')

%% Part 2b: Multidimensional space
% We now have 
    %allData: all Nflies as rows and 64 conditions in the columns
    %allClass: all 5 genotype labels to be assigned to the rows of allData

% Generate an interphenotype distance - pairwise correlations for each PT
interPTDist=corr(meanDat');

% Generate a distance matrix
distMat=(1-(interPTDist))/2;

% Let's do classifical Multidimensional Scaling using cmdscale
    % y returns coordinates in a 3d multidimensional space, the distances are given by
    % dMat, whilst e returns eigenvalues for each genotype.
[y,e]=cmdscale(distMat);

%Figure of multidimensional space
figure(4);
hold off;
for thisGT=1:length(gtName)
    gtScrubbed{thisGT}=strrep(gtName{thisGT},'_','-');
end
h=labelpoints(y(:,1),y(:,2)+y(:,3),gtScrubbed,'E',0.05,1);
hold on;
h=scatter(y(:,1),y(:,2)+y(:,3),[],1:nGenotypes,'filled');
hold off;
set(gca,'XLim',[-.04 .05]);
set(gca,'YLim',[-.04 .05]);

%% Part 2c: Leave One Out Classification
% We will use fitdiscr to try to classify our data and analyse resubLoss

% Define our training set and our assigned classes
allData=abs(allData);
trainingSet=allData;
trainingClass=allClass;

% and how many flies do we want to look at?
nFliesTotal=length(allClass);

% Fit a Discriminant Analysis Classifer
    % discrimObj = trained discriminant class model
    % allData = sample data
    % allClass = categories of our dataset
    
discrimObj = fitcdiscr(allData,allClass);

% Cross-validation model with 5 fold/set validation:
    % we partition our data into 5 random samples. For each 'fold' a classifier is trained on the remaining
    % data and tested on the fold
cvModel = crossval(discrimObj,'kfold',5);

%examine the losses for its folds
cverror = kfoldLoss(cvModel)

% Let's bootstrap the data. First we must set how many iterations we want
% the classifer to run through
nIter=1000;

% Run bootstrapped analysis
    % Input our classifier and how many iterations we want
    % Returns:
    %       cvError: Our cross validation error for each iteration
    %       pVal: Fraction of distrib above chance of .5 (correct prediction above chance/predictions made)*100
    %       confMat: Confusion matrix
tic
        [cvError, pVal,confMat] = flytv_bootstrapClassValsNWay(discrimObj,nIter);
toc    

normConfMat=confMat./repmat(nFliesInGt,nIter,1);

% Plot our classification accuracy for each genotype
figure(5);
for thisPT=1:nGenotypes
    ptName{thisGT}=dList(2+thisGT).name;
end
hold off;
boxplot(normConfMat, 'Widths', 0.4, 'labels',gtName);
hold on;
plot(0,1.1,10,.1);
xlabel('Genotype')
ylabel('Classification accuracy (%)')
title('N-Way classification accuracy of Drosophila genotypes')

% Classification tree
    % Here we generate a classification decision tree where we can see the decision
    % made in classifying a fly into its correct genotype based on response
    % amplitudes

tr = fitctree(allData,gtName(trainingClass),'MaxCat',nGenotypes,'CrossVal','on');

view(tr.Trained{2},'mode','graph');

% Let's look at what happens if we regularize the data

% Make a new discriminant model for the sake of it
discObjectReg=fitcdiscr(allData,allClass);

% Use cvshrink to regularize the model
[err,gamma,delta,numpred] = cvshrink(discObjectReg,...
    'NumGamma',29,'NumDelta',29,'Verbose',1);

% Plot: Do we get less error with less predictors?
% In this case no, it looks better with all the predictors! I won't go further.
figure(7);
plot(err,numpred,'k.')
xlabel('Error rate');
ylabel('Number of predictors');


%% Part 2d: Pairwise Classifications
% Here we compute pairwise classifications for all possible comparisons using a
% linear discrimination boundary 

% We use bootstrapClassVals2Way
%   Input the discrimination model and number of iterations
%   Output: cvError: Cross validation error/kFold loss
%           pVal: Fraction of distribution above chance rate of .5,
%               = 1-error*100

for thisGenotype1 = 1:(nGenotypes-1)
    for thisGenotype2 = (thisGenotype1+1):nGenotypes
        fprintf('\n%d and %d\n',thisGenotype1,thisGenotype2);
        thisDataPair = [allData(trainingClass==thisGenotype1,:);allData(trainingClass==thisGenotype2,:)];
        thisClassSet = [trainingClass(trainingClass==thisGenotype1);trainingClass(trainingClass==thisGenotype2)];
        
        %Generate a model for a pair of genotypes
        %pairdiscrimObj=fitcdiscr(thisDataPair,thisClassSet,'Gamma',1);
        pairdiscrimObj = fitcdiscr(thisDataPair,thisClassSet,'Gamma',1);
        
        tic
        %Compute
        [cvError, pVal] = flytv_bootstrapClassVals2Way(pairdiscrimObj, 1000);
        meanCVError(thisGenotype1,thisGenotype2) = mean(cvError); %We want this to be low!
        probVal(thisGenotype1,thisGenotype2) = pVal;
        
        toc
            
    fprintf('\nMean %.2f Prob %.2f\n',meanCVError(thisGenotype1,thisGenotype2),probVal(thisGenotype1,thisGenotype2));
    end %Run again for next pair
end 

Pair_AccUnreg = (1-meanCVError) * 100
Pair_pValUnReg = probVal

disp('Unregularized pairwise classifications complete')

%% Part 2e: Regularized Pairwise Classifications
% Here we essentially repeat the pairwise classifications except we use
% cvshrink which returns a cross-validated regularization of a linear
% discriminant analysis. We aren't passing any Gamma for the minute because
% it messes it up.

%This doesn't work I must pass gamma between 0 and 1... try to fix

for thisGenotype1=1:(nGenotypes-1)
    for thisGenotype2=(thisGenotype1+1):nGenotypes
        fprintf('\n%d and %d\n',thisGenotype1,thisGenotype2);
        thisDataPair=[allData(trainingClass==thisGenotype1,:);allData(trainingClass==thisGenotype2,:)];
        thisClassSet=[trainingClass(trainingClass==thisGenotype1);trainingClass(trainingClass==thisGenotype2)];
        discObject=fitcdiscr(thisDataPair,thisClassSet);
        
        %***regularize data***
        [err,gamma,delta,numpred] = cvshrink(discObject,  'NumGamma',29,'NumDelta',29,'Verbose',2);
        
        minerr = min(min(err));
        [p,q] = find(err == minerr);
        
        [numpred(p(1),q(1))];%; numpred(p(2),q(2))]
        clear reg_cverror;
        
        for thisP=1:length(p)
            
            regModel=discObject;
            regModel.Gamma = gamma(p(thisP));regModel.Delta = delta(p(thisP),q(thisP));
            reg_errorLoss=resubLoss(regModel);
            reg_cvmodel = crossval(regModel,'kfold',10);
            reg_cverror(thisP) = kfoldLoss(reg_cvmodel);
        end
       
        [minErr]=min(reg_cverror);
        minRegIndex=find(reg_cverror==minErr);
        minRegIndex=minRegIndex(1);
        regModel=discObject;
        regModel.Gamma = gamma(p(minRegIndex));
        regModel.Delta = delta(p(minRegIndex),q(minRegIndex));
        %******
        
        %cvError2 gives us our kfoldloss estimate - predictive inaccuracy
        %of classify. model. Lower the loss, better the prediction.
        %p value is gives faction of distribution above 50% classify rate
        tic
        [cvError2, pVal] = flytv_bootstrapClassVals2Way(regModel,1000);
        meanCVError2(thisGenotype1,thisGenotype2)=mean(cvError2);
        probVal2(thisGenotype1,thisGenotype2)=pVal;
        toc
    fprintf('\nMean %.2f Prob %.2f\n',meanCVError2(thisGenotype1,thisGenotype2),probVal2(thisGenotype1,thisGenotype2));
    end
end

% figure(30);
% subplot(1,2,1);
% imagesc(meanCVError2,[0 .5])   
% colorbar;
% subplot(1,2,2);
% imagesc(probVal2);
% colorbar;

Pair_AccReg = (1-meanCVError2) * 100
Pair_pValReg = probVal2

disp('Regularized pairwise classifications complete')

fprintf('\n*****\nClasses: %d (%.2f %% baseline correct), Unregularized mean error %.2f ', nGenotypes,(1/nGenotypes)*100,cverror);
fprintf('\n*****\nConservative percent correct: Orig %.2f',(1-cverror)*100);