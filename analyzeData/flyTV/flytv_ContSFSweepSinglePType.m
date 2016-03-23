%%load('/Users/alexwade/Downloads/Sweep1 08.04.14.mat') % it is possible to browse files using uigetfile
% This now takes a single directory with all the directories inside it.
% Computes all pair-wise classifications . Bootstraps means and CIs to give
% stats.
% This code is based on the code used to analyze the scientific reports
% paper.
% From 2016 onwards we are also interested in sweeping TF and Contrast
% This code plots those sweeps.
% Later we will try to classify them perhaps?


clear all
close all;
dataDir=uigetdir; %Brings up a dialog box to select a directory with the data.

% This is  a single phenotype directory.

fileList=dir(fullfile(dataDir,'*.mat')); %Gets a list of all the files in this directory. The first two are . and ..

%%


% Parse underscore chars in names so that we can print them

% ptName{ptIndex}=strrep(dList(thisPT).name,'_','-');
fList=dir(fullfile(dataDir,'*.mat')); % This should ignore the . and .. files because they don't end in .mat

nFiles=length(fList); %There are now two flies per file
% Generate an empty matrix of NaNs

%%
flyIndex=1;
for thisFile=1:nFiles
    fName=fullfile(dataDir,fList(thisFile).name)
    
    thisD=load(fName);
    [nRepeats,nTrials,nSamples,nFlies]=size(thisD.data)% Data is saved as nReps x nConditions x nSamples. It has to be re-sorted
    % Loop over trials extracting sf and tf for each one.
    
    for thisRep=1:nRepeats %Loop over repeats. We do this here because we might change the order of stim params between different repeats
        
        for thisTrial=1:nTrials
            %For this particular fly, we look at the
            trialMetadata=thisD.metaData{thisRep,thisTrial};
            sf(thisRep,thisTrial)=trialMetadata.stim.spatial.frequency(1); % Assumes both gratings have same Sf
            tf(thisRep,thisTrial)=trialMetadata.stim.temporal.frequency(1); % Assumes both gratings have same tf
            cont(thisRep,thisTrial)=trialMetadata.stim.cont(1);
            
            
        end %next trial
        shuffleSeq(thisRep,:)=trialMetadata.shuffleSeq; % Shuffleseq is the randomized presentation index. Store this per repeat to help with later sorting
        [sSeq,shuffleIndex(thisRep,:)]=sort(shuffleSeq(thisRep,:));
        
    end % next repeat
    
    
    for thisFly=1:nFlies
        for thisRep=1:nRepeats
            origDataStruct(flyIndex,thisRep,:,:)=thisD.data(thisRep,:,:,thisFly);
            
            dataStruct(flyIndex,thisRep,:,:)=thisD.data(thisRep,shuffleIndex(thisRep,:),:,thisFly);
            contList(flyIndex,thisRep,:)=cont(thisRep,shuffleIndex(thisRep,:));
            tfList(flyIndex,thisRep,:)=tf(thisRep,shuffleIndex(thisRep,:));
        end %Next rep
        
        
        flyIndex=flyIndex+1;
    end % next thisFly
    
    
    
    
end %Next file
%You should be able to get to here :)


%% we now have a set of sorted data (nFlies * nReps * nConditions x nsamples x nSecs)
% And a corresponding sf and tf for each one.
% Using unique we can assign an x and y index to each condition
[nFlies,nRepeats,nTrials,nSamples]=size(dataStruct);
for thisFly=1:nFlies
    for thisRep=1:nRepeats
        thisTfList=tfList(thisFly,thisRep,:)
        thisContList=contList(thisFly,thisRep,:);
        [uniqueCont,contIndexOut,contIndexIn]=unique(thisContList)
        [uniqueTF,tfIndexOut,tfIndexIn]=unique(thisTfList);
        nTrials=length(tfIndexIn);
        for thisTrial=1:nTrials
            fullDat(thisFly,thisRep,tfIndexIn(thisTrial),contIndexIn(thisTrial),:)=origDataStruct(thisFly,thisRep,thisTrial,:);
        end
        
    end
end

%%
% Now do some (coherent) averaging. Also crop out the right size of analysis time. NOTE: For the frequencies used
% here, we have all integers so we can use any set of 1Sec periods
secsToDump=1; %Get rid of the first second at the beginning to avoid onset transients.
durSecs=trialMetadata.stim.temporal.duration;  %How many seconds in total
secsToKeep=durSecs-secsToDump;
digitizerRate=length(trialMetadata.TimeStamps)/durSecs

%Check here :the digitizer rate should be an integer
if (digitizerRate ~= fix(digitizerRate))
    fprtinf('\nWarning!Non integer digitizer rate %.2d \nSetting to 1000 but beware!\n',digitizerRate);
    digitizerRate=1000;
end


croppedDat=fullDat(:,:,:,:,(secsToDump*digitizerRate+1):(secsToKeep*1000+secsToDump*digitizerRate));
%We have to get rid of drift and 50Hz
%We don't do this to all the data but...
%Here:do the FT, zero out the freq components between 48 and 52 and then do
%the ifft
%The result will be a filtered waveform.

% Plot some time courses
egSeq=croppedDat(:,3,4,[1,5],:);
egSeq=squeeze(egSeq);
meanSeq=squeeze(mean(egSeq,1));

rsSeq=reshape(meanSeq',1000,10,2);
overallSeq=squeeze(mean(rsSeq,2));
fOverall=fft(overallSeq);
fOverall(1,:)=0;
fOverall(48:52,:)=0;
fOverall((end-51):(end-48),:)=0;
reconSeq=real(ifft(fOverall));
%%
figure(99);
subplot(2,1,1);
c=plot(reconSeq);
xlabel('Time (ms)');
set(gca,'YLim',[-.025 .025]);
ylabel('Amplitude uVe-3');
subplot(2,1,2);
fDat=fft(reconSeq)/1000;
s=barweb(abs(fDat(2:25,:)),zeros(24,2),.5);
s=bar(abs(fDat(2:90,:)),.75);
xlabel('Temporal frequency (Hz)');
ylabel('Amplitude uVe-3');
set(c(1),'LineWidth',2);
set(c(2),'LineWidth',2);
set(c(1),'Color',[0 0 .4]);
set(c(2),'Color',[.8 .3 .3]);
% Compute the FT
ftAcrossReps=(fft(croppedDat,[],5)/(secsToKeep*1000));
[nFlies,nReps,nTFs,nSFs,nSamps]=size(ftAcrossReps)

tm=mean(ftAcrossReps,2);

fMeanAcrossReps=reshape(tm,[nFlies,nTFs,nSFs,nSamps]);



freqsToExtract=(uniqueTF*secsToKeep);
for thisFly=1:nFlies
    for thisTF=1:length(uniqueTF)
        for thisCont=1:length(uniqueCont)
            
            for thisHarmonic=1:2
                
                currF=freqsToExtract(thisTF)*thisHarmonic+1;
                extractedAmps(thisFly,thisTF,thisCont,thisHarmonic)=fMeanAcrossReps(thisFly,thisTF,thisCont,currF); %,freqsToExtract(thisTrial));
                ampPower(thisFly,thisTF,thisCont,thisHarmonic)=sqrt(sum(abs(fMeanAcrossReps(thisFly,thisTF,thisCont,1:50)).^2,4));
                coh(thisFly,thisTF,thisCont,thisHarmonic)=abs(extractedAmps(thisFly,thisTF,thisCont,thisHarmonic))./ampPower(thisFly,thisTF,thisCont,thisHarmonic);
                
            end % Next harmonic
        end % Next sf
    end % Next TF
end % Next Fly
% Place extracted data into a cell array
exAmps=extractedAmps;
ampPow=ampPower;
coherence=coh;


%% At this point we should be able to look at the average of the responses
%across flies
figure(11);
imagesc(squeeze(abs(mean(exAmps(:,:,:,2)))));
title('Mean coherence across flies');


%% All the important data are now in extractedAmps
% We are going to do a leave one out classification analysis on these data
% using classify
% This means that we leave a single fly out of the training set and try to
% classify it. Then we re-iterate with all the flies.
% Lets get all the data into a single array with amp, class - we'll do this
% just for the 2F data for now
nPhenotypes=ptIndex-1
allData=[];
allClass=[];
for thisPT=1:nPhenotypes
    thisData=squeeze(exAmps{thisPT}(:,:,:,2));
    figure(10);
    subplot(2,5,thisPT);
    mD=squeeze(mean(abs(thisData)));
    
    imagesc(abs(mD),[0 1e-2] );
    meanDat(thisPT,:)=mD(:);
    
    
    colormap hot;
    title(dList(thisPT+2).name);
    axis square
    
    
    [nFlies,nSF,nTF]=size(thisData);
    
    reshapedData=reshape(thisData,nFlies,nSF*nTF);
    classMarker=ones(nFlies,1)*thisPT;
    nFliesInPt(thisPT)=nFlies;
    
    allData=cat(1,allData,reshapedData); % These are still complex for now.
    allClass=cat(1,allClass,classMarker);
    
end
figure (11);
imagesc(abs(squeeze(thisData(3,:,:))),[0 6e-3]);
colormap hot;
colorbar;


%% mdscale
fMap=hsv(10);
interPTDist=corr(meanDat');
dMat=(1-(interPTDist))/2;
[y,e]=cmdscale(dMat);
figure(33);
hold off;
for thisPT=1:length(ptName)
    ptScrubbed{thisPT}=strrep(ptName{thisPT},'_','-');
end

h=labelpoints(y(:,1),y(:,2)+y(:,3),ptScrubbed,'E',0.05,1);
hold on;
h=scatter(y(:,1),y(:,2)+y(:,3),[],1:10,'filled');
hold off;
set(gca,'XLim',[-.075 .085]);
set(gca,'YLim',[-.075 .075]);







%
% % Try with all data
% interPTDistAll=corr(allData');
% dMatAll=(1-(interPTDistAll))/2;
% [yAll,eAll]=cmdscale(dMatAll);
% figure(34);
% labelpoints(y(:,1),y(:,2)+y(:,3),ptName,'E',0.05,1);
% %hold on;
% hAll=scatter(yAll(:,1),yAll(:,2),[],fMap(allClass,:),'filled');










%% Now do the 'leave one out' classification
classx=classify(abs(allData(1,:)),abs(allData(2:end,:)),allClass(2:end),'diaglinear');

% Now do the 'leave one out' classification
% How many flies to run over?
nFliesTotal=length(allClass);
allData=abs(allData);

% Matlab has some much nicer discriminant analysis toold. We will use these
% specifically the fitdiscr function and then analyze resubLoss


trainingSet=allData;
trainingClass=allClass;
discObject=fitcdiscr(allData,allClass);
discObjectAll=fitcdiscr(allData,allClass);
errorLoss=resubLoss(discObject)
cvmodel = crossval(discObject,'kfold',5)
cverror = kfoldLoss(cvmodel)

nIter=1000;

% Instead, we can run a bootstrapped multi-way analysis to get sig values
% for each P'type..
tic
[ cvError,pVal ,confMat] = flytv_bootstrapClassValsNWay(discObject,nIter );
toc

normConfMat=confMat./repmat(nFliesInPt,nIter,1);
confInterval95=prctile(normConfMat,[2.5,97.5]);

figure(99);
hold off;
barweb(mean(normConfMat),std(normConfMat));
hold on;
baselineRate=1/nPhenotypes;

h2=barweb(baselineRate,0);
set(gca,'YLim',[0 1]);

%%
figure(100);

for thisPT=1:nPhenotypes
    ptName{thisPT}=dList(2+thisPT).name;
end

hold off;
boxplot(normConfMat,'notch','on','labels',ptName);
hold on;
plot(0,1.1,10,.1);

tr=fitctree(allData,ptName(trainingClass),'MaxCat',nPhenotypes,'CrossVal','on');
figure(101);
hold off;
view(tr.Trained{2},'mode','graph');


N =15;
leafs=1:N;

for n=1:N
    t = fitctree(allData,ptName(trainingClass),'CrossVal','On',...
        'MinLeaf',leafs(n));
    err(n) = kfoldLoss(t);
end
figure(102);
plot(leafs,err);
xlabel('Min Leaf Size');
ylabel('cross-validated error');
minErrLeafSize=find(err==min(err));
optimalTree=fitctree(allData,ptName(trainingClass),'CrossVal','Off',...
    'MinLeaf',minErrLeafSize(1));
figure(103);
view(optimalTree,'mode','graph');


%%
% This version of the code computes all 2-way classifications.
% using a linear discriminant (SVD / quad can happen later)

for thisPhenotype1=1:(nPhenotypes-1)
    for thisPhenotype2=(thisPhenotype1+1):nPhenotypes
        fprintf('\n%d and %d\n',thisPhenotype1,thisPhenotype2);
        thisDataPair=[allData(trainingClass==thisPhenotype1,:);allData(trainingClass==thisPhenotype2,:)];
        thisClassSet=[trainingClass(trainingClass==thisPhenotype1);trainingClass(trainingClass==thisPhenotype2)];
        discObject=fitcdiscr(thisDataPair,thisClassSet,'Gamma',1);
        
        tic
        [ cvError,pVal ] = flytv_bootstrapClassVals2Way(discObject,1000 );
        meanCVError(thisPhenotype1,thisPhenotype2)=mean(cvError);
        probVal(thisPhenotype1,thisPhenotype2)=pVal;
        toc
        fprintf('\nMean %.2f Prob %.2f\n',meanCVError(thisPhenotype1,thisPhenotype2),probVal(thisPhenotype1,thisPhenotype2));
    end
end

figure(30);
subplot(1,2,1);
imagesc(meanCVError,[0 .5])
colorbar;
subplot(1,2,2);
imagesc(-log(probVal));
colorbar;

%% With regularization
for thisPhenotype1=1:(nPhenotypes-1)
    for thisPhenotype2=(thisPhenotype1+1):nPhenotypes
        fprintf('\n%d and %d\n',thisPhenotype1,thisPhenotype2);
        thisDataPair=[allData(trainingClass==thisPhenotype1,:);allData(trainingClass==thisPhenotype2,:)];
        thisClassSet=[trainingClass(trainingClass==thisPhenotype1);trainingClass(trainingClass==thisPhenotype2)];
        discObject=fitcdiscr(thisDataPair,thisClassSet);
        
        
        
        
        
        
        %****
        [err,gamma,delta,numpred] = cvshrink(discObject,  'NumGamma',29,'NumDelta',29,'Verbose',1);
        
        
        xlabel('Error rate');
        ylabel('Number of predictors');
        
        minerr = min(min(err));
        [p,q] = find(err == minerr)
        
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
        tic
        [ cvError2,pVal ] = flytv_bootstrapClassVals2Way(regModel,1000 );
        meanCVError2(thisPhenotype1,thisPhenotype2)=mean(cvError2);
        probVal2(thisPhenotype1,thisPhenotype2)=pVal;
        toc
        fprintf('\nMean %.2f Prob %.2f\n',meanCVError2(thisPhenotype1,thisPhenotype2),probVal2(thisPhenotype1,thisPhenotype2));
    end
end



%% Now do the classification using a subset of the components extracted via PCA
[p,s,l,tsq,expl]=pca(allData);
figure(1);
plot(expl);

% Going to take just the first n components
nComponents=7;
extractedPCA=p(:,1:nComponents);
figure(3);
for thisComp=1:nComponents
    subplot(nComponents,1,thisComp);
    imagesc(reshape(extractedPCA(:,thisComp),[8,8]),[0 .2]);
    colormap hot;
end

% Do the LOOut based only on the weights
% Quick sanity check first though:
% Each data set should be able to be reconstructed by weighted sum ofr
% first few components
% Let's take a look at, say , fly 10
reconIndexTest=3;

f10=allData(reconIndexTest,:);
recon10=p(:,1:nComponents)*(s(reconIndexTest,1:nComponents)');
figure(4);
subplot(2,1,1);
imagesc(reshape(f10,[8,8]));%,[0 .03]);
colorbar;
subplot(2,1,2);
imagesc(reshape(recon10',[8,8])-min(recon10(:)));%,[0 .01]);
colorbar;
colormap hot

%% Fine....
for thisCompSet=1:20
    extractedWeights=s(:,1:thisCompSet);
    
    pcaDisc=fitcdiscr(extractedWeights,allClass);
    pca_errorLoss=resubLoss(pcaDisc)
    tic
    pca_cvmodel = crossval(pcaDisc,'kfold',2);
    
    
    pca_cverror(thisCompSet) = kfoldLoss(pca_cvmodel);
    
    
    toc
    
end
hist(pca_cverror(:,8));

extractedWeights=s(:,1:8);

pcaDisc2=fitcdiscr(extractedWeights,allClass);
tic
[ pca_cvError2,pVal ] = flytv_bootstrapClassVals2Way(pcaDisc2,1000 );
toc


figure(19);

hist(pca_cvError2,15);
disp(pVal);

%% Here do the n-way version
% Instead, we can run a bootstrapped multi-way analysis to get sig values
% for each P'type..
tic
[ cvErrorPCA,pValPCA ,confMatPCA] = flytv_bootstrapClassValsNWay(pcaDisc2,nIter );
toc

normConfMatPCA=confMatPCA./repmat(nFliesInPt,nIter,1);
confInterval95PCA=prctile(normConfMatPCA,[2.5,97.5]);

figure(199);
hold off;
barweb(mean(normConfMatPCA),std(normConfMatPCA));
hold on;
baselineRate=1/nPhenotypes;

h2=barweb(baselineRate,0);
set(gca,'YLim',[0 1]);


figure(200);

hold off;
boxplot(normConfMatPCA,'notch','on','labels',ptName);
hold on;
plot(0,1.1,10,.1);
ttest(normConfMatPCA,1/9,'alpha',.01)

disp(sum(normConfMat<(1/9))/length(normConfMatPCA));


% Check stats - compare to the 1/10 random baseline


%% The final thing to check :
% Can we use matlab's own reguarization to make things better than our PCA
rng(8000,'twister') % For reproducibility
[err,gamma,delta,numpred] = cvshrink(discObjectAll,...
    'NumGamma',29,'NumDelta',29,'Verbose',1);
%%
figure;
plot(err,numpred,'k.')
xlabel('Error rate');
ylabel('Number of predictors');

minerr = min(min(err));
[p,q] = find(err == minerr)

[numpred(p(1),q(1))];%; numpred(p(2),q(2))]
for thisP=1:length(p)
    
    regModel=discObjectAll;
    regModel.Gamma = gamma(p(thisP));regModel.Delta = delta(p(thisP),q(thisP));
    reg_errorLoss=resubLoss(regModel);
    reg_cvmodel = crossval(regModel,'kfold',10);
    reg_cverror(thisP) = kfoldLoss(reg_cvmodel);
end
[minErr]=min(reg_cverror);
minRegIndex=find(reg_cverror==minErr);
minRegIndex=minRegIndex(1);
regModel=discObjectAll;
regModel.Gamma = gamma(p(minRegIndex));regModel.Delta = delta(p(minRegIndex),q(minRegIndex));
tic
for t=1:1000
    reg_cvmodel = crossval(regModel,'kfold',2);
    reg_cverror2(t) = kfoldLoss(reg_cvmodel);
end
toc
figure(20);
hist(reg_cverror2,15);
sum(reg_cverror2>.5)
tic
[ cvErrorReg,pValReg ,confMatReg] = flytv_bootstrapClassValsNWay(regModel,nIter );
toc

normConfMatReg=confMatReg./repmat(nFliesInPt,nIter,1);
confInterval95Reg=prctile(normConfMatReg,[2.5,97.5]);
%%
figure(400);

hold off;
boxplot(normConfMatReg,'notch','on','labels',ptName);
hold on;
plot(0,1.1,10,.1);
ttest(normConfMatReg,1/9,'alpha',.01)

disp(sum(normConfMat<(1/9))/length(normConfMatReg));
%%
fprintf('\n*************\nClasses: %d (%.2f %% baseline correct), Orig error %.2f, PCA error %.2f, REG error %.2f\n',nPhenotypes,(1/nPhenotypes)*100,cverror,min(pca_cverror),minErr(1));
fprintf('\n*************\nConservative percent correct: Orig %.2f, PCA method %.2f, REG method %.2f\n',(1-cverror)*100,(1-min(pca_cverror))*100,(1-minErr(1))*100);


Rorig = confusionmat(discObject.Y,resubPredict(discObject))
regModel=discObject;
regModel.Gamma = gamma(p(minRegIndex(1)));regModel.Delta = delta(p(minRegIndex),q(minRegIndex));
Rreg = confusionmat(regModel.Y,resubPredict(regModel))
