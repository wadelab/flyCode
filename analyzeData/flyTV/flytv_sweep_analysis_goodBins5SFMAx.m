%load('/Users/alexwade/Downloads/Sweep1 08.04.14.mat') % it is possible to browse files using uigetfile
clear all
close all;
dataDir=uigetdir;
fList=dir(fullfile(dataDir,'*.mat'))

nFlies=length(fList);
% Generate an empty matrix of NaNs

%%
for thisFly=1:nFlies
    fName=fullfile(dataDir,fList(thisFly).name)
    
    
    dataSetName=fullfile(fName); % Fullfile generates a legal filename on any platform
    
    thisD=load(dataSetName);
    [nRepeats,nTrials,nSamples]=size(thisD.data)% Data is saved as nReps x nConditions x nSamples. It has to be re-sorted
    % Loop over trials extracting sf and tf for each one.
    for thisRep=1:nRepeats
        for thisTrial=1:nTrials
            
            trialMetadata=thisD.metaData{thisRep,thisTrial};
            sf(thisRep,thisTrial)=trialMetadata.stim.spatial.frequency(1); % Assumes both gratings have same Sf
            tf(thisRep,thisTrial)=trialMetadata.stim.temporal.frequency(1); % Assumes both gratings have same tf
            
            
            
            shuffleSeq(thisRep,:)=trialMetadata.shuffleSeq; % Shuffleseq is the randomized presentation index
            [sSeq,i]=sort(shuffleSeq(thisRep,:));
            
        end
        datStruct(thisFly,thisRep,:,:)=thisD.data(thisRep,:,:);
        tfList(thisFly,thisRep,:)=tf(thisRep,:);
        sfList(thisFly,thisRep,:)=sf(thisRep,:);
        
    end
    
end


%% For each fly, we now have a set of unsorted data (nReps * nConditions x nsamples x nSecs)
% And a corresponding sf and tf for each one.
% Using unique we can assign an x and y index to each condition
for thisFly=1:nFlies
    for thisRep=1:nRepeats
        thisSfList=sfList(thisFly,thisRep,:);
        thisTfList=tfList(thisFly,thisRep,:);
        [uniqueSF,sfIndexOut,sfIndexIn]=unique(thisSfList);
        [uniqueTF,tfIndexOut,tfIndexIn]=unique(thisTfList);
        nTrials=length(tfIndexIn);
        for thisTrial=1:nTrials
            fullDat(thisFly,thisRep,tfIndexIn(thisTrial),sfIndexIn(thisTrial),:)=datStruct(thisFly,thisRep,thisTrial,:);
        end
        
    end
end

%%
% Now do some (coherent) averaging. Also crop out the right size of analysis time. NOTE: For the frequencies used
% here, we have all integers so we can use any set of 1Sec periods
durSecs=10;
croppedDat=fullDat(:,:,:,:,1001:(durSecs*1000+1000));


% Compute the FT
ftAcrossReps=(fft(croppedDat,[],5)/(durSecs*1000));
[nFlies,nReps,nTFs,nSFs,nSamps]=size(ftAcrossReps);


tm=mean(ftAcrossReps,2);

fMeanAcrossReps=reshape(tm,[nFlies,nTFs,nSFs,nSamps]);



freqsToExtract=(uniqueTF*durSecs);
for thisFly=1:nFlies
    for thisTF=1:length(uniqueTF)
        for thisSF=1:length(uniqueSF)
            
            for thisHarmonic=1:2
                
                currF=freqsToExtract(thisTF)*thisHarmonic+1;
                extractedAmps(thisFly,thisTF,thisSF,thisHarmonic)=fMeanAcrossReps(thisFly,thisTF,thisSF,currF); %,freqsToExtract(thisTrial));
                ampPower(thisFly,thisTF,thisSF,thisHarmonic)=sqrt(sum(fMeanAcrossReps(thisFly,thisTF,thisSF,1:50).^2,4));
                coh(thisFly,thisTF,thisSF,thisHarmonic)=abs(extractedAmps(thisFly,thisTF,thisSF,thisHarmonic))./ampPower(thisFly,thisTF,thisSF,thisHarmonic);
                
            end % Next harmonic
        end % Next sf
    end % Next TF
end % Next Fly

%%
%plot 3D temporal landscapes

mExtracted=abs((mean(abs(extractedAmps))));
SEM=std(abs(extractedAmps))/sqrt(length(extractedAmps))
SEM=reshape(SEM,[nTFs,nSFs,2]);
mExtracted=reshape(mExtracted,[nTFs,nSFs,2]);

if (sum(size(mExtracted)==1)==0) % Check to make sure that all dimensions have at least 2 entries - else you can't make a surface you have to just plot the data...
    
    
figure(10);
hold off;
subtightplot(1,3,1,.03);
surfc(squeeze(mExtracted(:,:,1)));colorbar('off');
shading 'interp'
ylabel('Temporal Frequency (Hz)');
xlabel('Spatial Frequency (cpd)');
az=-37.5;
el=15
view(az,el)
set(gca,'PlotBoxAspectRatio',[1 1 1]);
set(gca,'YTickLabel',uniqueTF);
set(gca,'XTickLabel',uniqueSF);
%set(gca,'XTick',0:2:8);
colormap hot; colorbar('off');
subtightplot(1,3,2,.03);
surfc(squeeze(mExtracted(:,:,2)));colorbar('off');
shading 'interp'
whitebg('black')
set(gcf, 'color', [0 0 0])
ylabel('Temporal Frequency (Hz)');
xlabel('Spatial Frequency (cpd)');
az=-37.5;
el=15
view(az,el)
set(gca,'PlotBoxAspectRatio',[1 1 1]);
set(gca,'YTickLabel',uniqueTF);
set(gca,'XTickLabel',uniqueSF);
colormap hot; colorbar('off');
subtightplot(1,3,3,.03);
a=squeeze(mExtracted(:,:,2)./squeeze((mExtracted(:,:,1)+mExtracted(:,:,2)))),[0 1];
surfc(a);colorbar('off')
colorbar;
shading 'interp'
ylabel('Temporal Frequency (Hz)');
xlabel('Spatial Frequency (cpd)');
az=-37.5;
el=15
view(az,el)
%set(get(gca,'xlabel'),'rotation',12.2)
%set(get(gca,'ylabel'),'rotation',341.5)
set(gca,'PlotBoxAspectRatio',[1 1 1]);
set(gca,'YTickLabel',uniqueTF );
set(gca,'XTickLabel',uniqueSF);
colormap hot; colorbar('off');
%%
%plot 2D temporal plot
figure(11);
hold off;
subtightplot(1,3,1,.03);
imagesc(squeeze(mExtracted(:,:,1)));colorbar;
ylabel('Temporal Frequency (Hz)');
xlabel('Spatial Frequency (cpd)');
set(gca,'YTickLabel',uniqueTF );
set(gca,'XTickLabel',uniqueSF);
colormap hot; colorbar;
box('off')
subtightplot(1,3,2,.03);
%imagesc(squeeze(mExtracted(:,:,2)));colorbar;
%imagesc(squeeze(mExtracted(:,:,2)),[0 10e-3]);colorbar;
imagesc(squeeze(mExtracted(:,:,2)),[0 2.7e-3]);colorbar;
shading 'interp'
whitebg('black')
ylabel('Temporal Frequency (Hz)');
xlabel('Spatial Frequency (cpd)');
set(gca,'YTickLabel',uniqueTF );
set(gca,'XTickLabel',uniqueSF);
colormap hot; colorbar;
box('off')
subtightplot(1,3,3,.03);
imagesc(squeeze(mExtracted(:,:,2)./squeeze((mExtracted(:,:,1)+mExtracted(:,:,2)))),[0 1]);
colorbar;
ylabel('Temporal Frequency (Hz)');
xlabel('Spatial Frequency (cpd)');
set(gca,'YTickLabel',uniqueTF );
set(gca,'XTickLabel',uniqueSF);
colormap hot; colorbar;
box('off')
whitebg('black')
set(gcf, 'color', [0 0 0])

%%
%plot TF's against Response for Individual SF's

%mExtracted=abs(squeeze(mean(abs(extractedAmps))));
figure(8);
%subplot(2,1,1);plot(mExtracted(:,:,2));
subplot(2,1,1);errorbar(mExtracted(:,:,2),SEM(:,:,2));
set(gcf, 'color', [0 0 0])
xlabel('Temporal Frequency (Hz)');
ylabel('Response Amplitude');
box('off')
Start=[0]
Start=transpose(Start)
uniqueTFL=[Start;uniqueTF]
xlim([0 8]);
set(gca,'XTickLabel',uniqueTFL);
SFleg=num2str(uniqueSF);
hleg=legend(SFleg,'location','NorthEastOutside');
htitle=get(hleg,'title');
set(htitle,'String','Spatial Frequency (cpd)');
set(hleg, 'EdgeColor', [0,0,0]);


% and plot SF's against Response for Individual TF's
TransExtracted=transpose(mExtracted(:,:,2))
subplot(2,1,2);errorbar(TransExtracted,SEM(:,:,2));
set(gcf, 'color', [0 0 0])
xlabel('Spatial Frequency (cpd)');
ylabel('Response Amplitude');
box('off')
Start2=[0]
Start2=transpose(Start2)
uniqueSFL=[Start2;uniqueSF]
xlim([0 8]);
set(gca,'XTickLabel',uniqueSFL);
TFleg=num2str(uniqueTF);
hleg2=legend(TFleg,'location','NorthEastOutside');
htitle=get(hleg2,'title');
set(htitle,'String','Temporal Frequency (Hz)');
set(hleg2, 'EdgeColor', [0,0,0]);

end

if not (sum(size(mExtracted)==1)==0)

% and plot SF's against Response for Individual TF's
TransExtracted=transpose(mExtracted(:,:,2))
subplot(2,1,1);errorbar(TransExtracted,SEM(:,:,2));
set(gcf, 'color', [0 0 0])
set(gca,'XTickLabel',uniqueSF);
xlabel('Spatial Frequency (cpd)');
ylabel('Response Amplitude');
box('off')
TFleg=num2str(uniqueTF);
hleg2=legend(TFleg,'location','NorthEastOutside');
htitle=get(hleg2,'title');
set(htitle,'String','Temporal Frequency (Hz)');
set(hleg2, 'EdgeColor', [0,0,0]);

%plot 2D temporal plot
mExtracted=abs(squeeze(mean(abs(TransExtracted))));


TTransExtracted=transpose(TransExtracted);
subplot(2,1,2);imagesc(squeeze(TTransExtracted),[0 1.7e-3]);colorbar;
ylabel('Temporal Frequency (Hz)');
xlabel('Spatial Frequency (cpd)');
set(gca,'YTickLabel',uniqueTF );
set(gca,'XTickLabel',uniqueSF);
colormap hot; colorbar;
box('off')

end

return;