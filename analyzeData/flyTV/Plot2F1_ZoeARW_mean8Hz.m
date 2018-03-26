clear all
close all;
dataDir=uigetdir('c:\data\SSERG\data\Zoe\ALL_DATA_COLLATED');
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


% 
mExtracted=abs((mean(abs(extractedAmps))));
SEM=std(abs(extractedAmps))/sqrt(length(extractedAmps))
SEM=reshape(SEM,[nTFs,nSFs,2]);
mExtracted=reshape(mExtracted,[nTFs,nSFs,2]);

only8Hz2ndHm=squeeze(extractedAmps(:,5,:,2));

mean8HzPerFly=mean(abs(only8Hz2ndHm(:)),2);
grandMean8Hz=mean(mean8HzPerFly(:));
semMean8Hz=std(mean8HzPerFly(:))/sqrt(length(mean8HzPerFly(:)));
figure(100);
barweb(grandMean8Hz,semMean8Hz,.6);
set(gca,'YLim',[0 8e-3]);

fprintf('\n**********   At 8Hz the mean amplitude is %.3d and the SEM is %.3d **********\n',grandMean8Hz,semMean8Hz);

%%%plot 3D temporal landscapes
if (sum(size(mExtracted)==1)==0) % Check to make sure that all dimensions have at least 2 entries - else you can't make a surface you have to just plot the data...
    

figure(1);
hold off;


spt1=subtightplot(2,2,1,0.1);
set(spt1,'position',[0.051 0.548 0.34 0.4]);
imagesc(squeeze(mExtracted(:,:,2)),[0 11e-3]);colorbar;
shading 'interp'
ylabel('Temporal Frequency (Hz)');
xlabel('Spatial Frequency (cpd)');
set(gca,'YTickLabel',uniqueTF );
set(gca,'XTickLabel',uniqueSF);
colormap hot; colorbar;
box('off')

mExtracted=abs(squeeze(mean(abs(extractedAmps))));
spt4=subtightplot(2,2,4,0.1);errorbar(mExtracted(:,:,2),SEM(:,:,2));
set(spt4,'position',[0.469 0.073 0.32 0.377]);
xlabel('Temporal Frequency (Hz)');
ylabel('Response Amplitude');
box('off')
Start=[0]
Start=transpose(Start)
uniqueTFL=[Start;uniqueTF]
xlim([0 8]);
ylim([0 12e-3]);
set(gca,'XTickLabel',uniqueTFL);
SFleg=num2str(uniqueSF);
%hleg=legend(SFleg,'location','NorthEastOutside');
subleg=annotation('textbox',[0.8 0.45 0.16 0.03], 'string', 'Spatial Frequency (cpd)');
set(subleg, 'EdgeColor', [1,1,1]);
%set(hleg, 'EdgeColor', [1 1 1]);
hleg=legend(SFleg,'location',[0.823 0.29 0.072 0.161]);
%htitle=get(hleg,'title');
%set(htitle,'String','Spatial Frequency (cpd)');
set(hleg, 'EdgeColor', [1,1,1]);

TransExtracted=transpose(mExtracted(:,:,2))
spt2=subtightplot(2,2,2,0.1);errorbar(TransExtracted,SEM(:,:,2));
set(spt2,'position',[0.469 0.548 0.32 0.341]);
xlabel('Spatial Frequency (cpd)');
ylabel('Response Amplitude');
box('off')
Start2=[0]
Start2=transpose(Start2)
uniqueSFL=[Start2;uniqueSF]
%xlim('manual');
xlim([0 8]);
%ylim('manual');
ylim([0 12e-3]);
set(gca,'XTickLabel',uniqueSFL);
TFleg=num2str(uniqueTF);
hleg2=legend(TFleg,'location',[0.823 0.741 0.058 0.164]);
subleg=annotation('textbox',[0.8 0.9 0.16 0.03], 'string', 'Temporal Frequency (Hz)');
set(subleg, 'EdgeColor', [1,1,1]);
set(hleg2, 'EdgeColor', [1 1 1]);

spt3=subtightplot(2,2,3,0.1);
set(spt3,'position',[-0.004 0.066 0.429 0.4]);
surfc(squeeze(mExtracted(:,:,2)));colorbar('off');
%zlim([0 11e-3]);
caxis([0 0.01]);
shading 'interp'
whitebg('white')
set(gcf, 'color', 'white')
ylab=ylabel('Temporal Frequency (Hz)');
%set(ylab, 'position', [8.107 11.328 -0.004]);
set(ylab, 'rotation', [-21]);
pos=get(ylab, 'position');
ylimits=get(gca,'ylim')'
pos(2)=ylimits(1)-0.08*(ylimits(2)-ylimits(1));
set(ylab,'position',pos);
xlab=xlabel('Spatial Frequency (cpd)');
%set(xlab, 'position', [9.638 10.183 -0.004]);
set(xlab, 'rotation', [10]);
posx=get(xlab, 'position');
xlimits=get(gca,'xlim')'
posx(2)=xlimits(1)-0.45*(xlimits(2)-xlimits(1));
set(xlab,'position',posx);
az=-37.5;
el=15
view(az,el)
set(gca,'PlotBoxAspectRatio',[1 1 1]);
set(gca,'YTickLabel',uniqueTF(2:2:8));
set(gca,'XTickLabel',uniqueSF(1:2:end));
set(gca,'FontName','Arial')
set(gca,'FontSize', 10)
colormap hot; colorbar('off');
x0=10;y0=10;width=900;height=500;
set(gcf,'units','points','position',[x0,y0,width,height]);
xt=1:2:8;
x1=[1 8];
set(gca,'xTick',xt,'Xlim',x1);
colormap hot; colorbar('off');
zlab=zlabel('Response Amplitude');

set(gcf, 'color', [1 1 1]);
fprintf('\n**********   At 8Hz the mean amplitude is %.3d and the SEM is %.3d **********\n',grandMean8Hz,semMean8Hz);

end;
return;