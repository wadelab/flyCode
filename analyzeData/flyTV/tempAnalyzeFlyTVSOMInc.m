clear all;
close all;

fList=dir('/Users/alexwade/Google Drive/FlyTV/SOM_SOC/*.mat');

%fList={'flyTV_SOM_20140822T115543.mat','flyTV_SOM_20140822T124534.mat'};
dTotal=[];
sfTotal=[];
for thisF=1:length(fList)
    thisData=load(fList(thisF).name);
    % Trial by trial data are in thisData.data: nConds x nReps x
    % nTimePoints
    dTotal=cat(1,dTotal,thisData.data);
    
    % Thisdata.metaData is a cell array containing all the important info
    % about each run. It is nReps x nConds - in this case 20 x 6
    [nReps,nConds]=size(thisData.metaData);
    
    for thisCond=1:nConds
        for thisRep=1:nReps
            sf(thisF,thisRep,thisCond,:)=thisData.metaData{thisRep,thisCond}.stim.spatial.frequency;
            tf(thisF,thisRep,thisCond,:)=thisData.metaData{thisRep,thisCond}.stim.temporal.frequency;

        end
    end
    sfTotal=cat(1,sfTotal,squeeze(sf(thisF,:,:,:)));
    
    
    
end

% Sort the data by carrier frequency (since this is all that gets changed)
cFreq=squeeze(sfTotal(:,:,2));
[sequenceArray,sortArray]=sort(cFreq(:));
nPointsTotal=size(dTotal,3);


dataArray=reshape(dTotal,(thisF*nConds*nReps),nPointsTotal);
datSorted=dataArray(sortArray,:);
datSortedConds=reshape(datSorted,[length(fList)*nReps,nConds,nPointsTotal]);
% Reshape the time array and average across 1second bins
datMeanCondsBinned=reshape(datSortedConds(:,:,1001:end),[length(fList)*nReps,nConds,1000,10]);
fDatMeanBinned=fft(datMeanCondsBinned,[],3);

% Compute the FFT for incoherent averaging.
fMeanDatAbs=squeeze(mean((fDatMeanBinned),4));
fMeanDatAllConds=squeeze(mean(fMeanDatAbs,1));

figure(1);
imagesc(squeeze(abs(fMeanDatAllConds(:,2:17))));
% Now sort by carrier frequency
xlabel('Temporal frequency (Hz)');
ylabel('Spatial freq carrier (cpd)');
set(gca,'YTickLabel',thisData.sfList(:,2));
colormap hot;
colorbar;

figure(2)
h=plot(squeeze(abs(fMeanDatAllConds(:,2:17)))');
set(h,'LineWidth',2);
whitebg([0 0 0]);

legend((num2str(thisData.sfList(:,2))));

return;


croppedData=dTotal(:,:,1001:end);
[nReps,nConds,tPoints]=size(croppedData);


% Reshape to 1sec bins
reshapedCropped=reshape(croppedData,[nReps,nConds,1000,10]);
meanReshaped=squeeze(mean(reshapedCropped,4));

disp('Current dbstack : **** ---');

disp(dbstack);
ftCropped=fft(meanReshaped,[],3);

% Take a look average across all conds
meanFTCropped=squeeze(mean(ftCropped));
mmFT=mean(meanFTCropped);
bar(abs(mmFT(2:49)));



