% This version copes with randomized contrast sequences produced by newer
% versions of the display code.
% It expects the indices of the random sequence to be in
% exptParams{x}.randSeq

clear all; close all;
%dirList={'wt_Blue_062612','ort_Blue_62612'};
%dirList={'wt_Green_062612','ort_Green_062612'};
%dirList={'combinedWT_062612','combinedKCC_All_062912'};
%dirList={'combinedWT_062612','combinedORT_062612'};
baseDir='/MRI/data/flyData/SSERG/datasets/NazPD';

d=dir([baseDir,'/allKCC*']);
dIndex=1;
for t=1:length(d);
    if (d(t).isdir)
        dirList{dIndex}=fullfile(baseDir,d(t).name);
        dname{dIndex}=d(t).name;
        dIndex=dIndex+1;
    end
end
disp('Directory list:');
disp(dirList);

%dirList={'allW-','allG2019Sd1','allG2019S28','allhLRRK2d1','allhLRRK2d1August','AllCSW28','allKCC','allKCCd10','allpark','allG2019Sd1','AllG2019sd10','allG2019S28','allG2019Sd1August','allhLRRK2'};
%%,'WT-080312_KCCCOntrol','Kcc_1Day_LowInt_080312'}; 

ACCEPT_ALL=1; % If this is 1 then we accept all data sets. If it's zero, we ask each time we load something

for thisDirIndex=1:length(dirList)
    pathName=fullfile(dirList{thisDirIndex},'*.mat');
    fileNameList=dir(pathName)
    nDataSets(thisDirIndex)=length(fileNameList);
    clear respFreqs;
    goodIndex=1;
    for thisFileIndex=1:nDataSets(thisDirIndex)
        fName=fullfile(dirList{thisDirIndex},fileNameList(thisFileIndex).name);
        fprintf('\nCurrently loading %s\n',fName);
        a=load(fName); % These files are very big so we have to extract data as we go.
        %%For now we want 4 harmonics from each data set: 1F1, 1F2, 2F1,
        %2F2
        %The data are in a.d which is nSamples x nChannels * nContrasts *
        %nExpts
        %Condition it a bit. Chop out bins
        condDat=a.d((a.digitizerSampleRate*a.nPreBins+1):end,:,:);
        %Reformat into bins
        condDat=reshape(condDat,[a.digitizerSampleRate,a.exptParams{1}.binsPerTrial,2,a.exptParams{1}.nTrials,length(a.exptParams)]);
        
         
      % Here we can re-order meanCondDat to generate plots in order of contrast.
        for thisExpt=1:length(a.exptParams)
            [dummy,sortSeq{thisExpt}]=sort(a.exptParams{thisExpt}.randSeq(:,1));
          condDat(:,:,:,:,thisExpt)=condDat(:,:,:,sortSeq{thisExpt},thisExpt);
      
        end
        %Compute the average across bins. This throws away bin-to-bin information
        fftMeanTimeData=fft(condDat);
        
       
        % Compute the distortion in the output, input.
        freqsToExtract=[a.exptParams{1}.F(1);a.exptParams{2}.F(2);2*a.exptParams{1}.F(1);2*a.exptParams{1}.F(2);a.exptParams{1}.F(1)+a.exptParams{1}.F(2);a.exptParams{1}.F(2)-a.exptParams{1}.F(1)];
         
        
        fftData=squeeze(mean(fftMeanTimeData,2));
        stdCondDat=squeeze(std(fftMeanTimeData,[],2));
        
        % Compute FFTs and look at the 1F1 and 1F2 components
        %fftData=fft(meanCondDat);
        rf=squeeze(fftData(1+freqsToExtract,:,:,:));
        sems=squeeze(stdCondDat(1+freqsToExtract,:,:,:));
          %%  % As a form of qa we're going to display the 1F1 CRF and ask if
        % this data set should be included
        % We will also scale everything to the mean of the last three data
        % points in the 1F1
        scaleVal(thisDirIndex)=mean(rf(1,1,(end-2):end,1));
        rf=rf/scaleVal(thisDirIndex);
        sems=sems/scaleVal(thisDirIndex);
        figure(1);
          % Do the thing below to fit log contrast onto a plot
    
    contRange=a.exptParams{1}.contRange(sortSeq{1},1);
    %contRange(2,:)=contRange(1,:);
        contRange(1,:)=0.01;
        errorbar(contRange,abs(squeeze(rf(1,1,:,1))),sems(1,1,:,1));
        if (~ACCEPT_ALL)
            user_entry = input('ok?','s') ;
            accepted=~strcmp(user_entry,'n');
        else
            accepted=1;
        end
        
        if (accepted)
            fprintf(' *** Accepted \n');
            respFreqs(goodIndex,:,:,:,:)=rf;
            goodIndex=goodIndex+1;
            % Make a list of the accepted files so we can recreate later if
            % required
            fNameTested{thisDirIndex}{thisFileIndex}=fName;
            acceptedList{thisDirIndex}(thisFileIndex)=accepted;
            
        end
       % This is now nFiles * nFreqs * nChannels * nContrasts * nExpts
       
      
    end
        % can now average down files in complex domain
        avRespFreq=squeeze(mean(respFreqs));
        stdRespFreq=squeeze(std(respFreqs)); % Note - in both cases these are made on the complex vals
        semRespFreq=stdRespFreq/sqrt(size(respFreqs,1));
        allData{thisDirIndex}=respFreqs;
        allMeanData{thisDirIndex}=avRespFreq; % Save the mean values
        allSemData{thisDirIndex}=semRespFreq; % Save the SEMs

       
        
end

%We now have all the data in. The first index is a fly type (usually).
%As a first pass, loop over this and average all data within.
%contRange=a.exptParams{1}.contRange(:,1);
%%

save('allData');

contRange(1)=0.01;
labelList={'1F1','1F2','2F1','2F2','F1+F2','F2-F1'};
maxLim=[1.2 1.2 0.8 0.8 0.3 0.3];
for thisDirIndex=1:length(dirList)
    % Note - we'll also extract some nice numbers to summarize the data.
    % These are:
    % Scaled peak of masked 1F1 vals (unmasked vals are ==1 by default)
    % Average phase lags of all conditions
    % Max of 2F1 terms
    % Max of IM terms
    
    clear dataSet;
    
      avRespFreqs=allMeanData{thisDirIndex};
      semRespFreqs=allSemData{thisDirIndex};
      
      figure(thisDirIndex);
      
      for t=1:size(avRespFreqs,1)
      crf=squeeze(avRespFreqs(t,1,:,:));
      sem=squeeze(semRespFreqs(t,1,:,:));
      subplot(3,2,t);
      %subplot(1,size(avRespFreqs,1),t);
      hold off;
      h=errorbar(contRange,abs(crf(:,1)),sem(:,1),'k');
      set(h,'LineWidth',2);
      set(h,'Color',[0.2 0.2 0.2]);
      
      
      hold on;
      h=errorbar(contRange,abs(crf(:,2)),sem(:,2),'r');
      
      
      set(h,'Color',[0.4 0.4 0.4]);
      set(h,'LineWidth',2);
      %set(gca,'DataAspectRatio',[1 5 1]);
      grid on;
      axis square
     %gridcolor([0.7 0.7 0.7],[0.7 0.7 0.7]);
      %l=legend(labelList{t},[labelList{t},' 30% mask']);
      %set(l,'Orientation','Horizontal');
      
      set(gca,'XScale','Log');
      xlabel('Probe Contrast');
      ylabel('Resp amplitude');
      set(gca,'YLim',[0 maxLim(t)]);
      set(gca,'XLim',[0 0.8]);
      title(sprintf('%s\n%s',dname{thisDirIndex},labelList{t}));
      
      end
       fname=sprintf('%s_CART',dirList{thisDirIndex});
    
    print('-depsc', fname);  
%       
%       % Also plot the phases
%         figure(thisDirIndex+10);
%       for t=1:size(avRespFreqs,1)
%       crf=squeeze(avRespFreqs(t,1,:,:));
%       subplot(size(avRespFreqs,1),1,t);
%       hold off;
%       plot(contRange,unwrap(angle(crf(:,1))),'k');
%       hold on;
%       plot(contRange,unwrap(angle(crf(:,2))),'r');
%       grid on;
%       set(gca,'XScale','Log');
%         xlabel('Probe Contrast');
%       ylabel('Resp phase');
%       axis square
%       end
      
      % Also make polar plots
       figure(thisDirIndex+20);   
        for t=1:size(avRespFreqs,1) 
            subplot(3,2,t);
            crf=squeeze(avRespFreqs(t,1,:,:));
            hold off;
            h1=compass(real(crf(:,2)),imag(crf(:,2)),'r');  
            for th=1:length(h1)
                set(h1(th),'Color',[1 0.6 0.6]-0.05*th); 
                set(h1(th),'LineWidth',1.5);
            end
            hold on;
            h2=compass(real(crf(:,1)),imag(crf(:,1)),'k');
            set(gca,'FontSize',8);
            
            for th=1:length(h2)
                set(h2(th),'Color',[0.6 0.6 0.6]-0.05*th); 
                set(h2(th),'LineWidth',1.5);
            end
            ttl=sprintf('%s\n%s',dname{thisDirIndex},labelList{t});
    title(ttl);
    th = findall(gcf,'Type','text');

    % TODO HERE - Compute mean angle, some other stats - put into a big
    % matrix for an ANOVA
    
for i = 1:length(th),
set(th(i),'FontSize',6)
end
    fname=sprintf('%s_polar',dirList{thisDirIndex});
    
    print('-depsc', fname);
    
    
%             polar(angle(crf(:,1)),abs(crf(:,1)),'k');
%             hold on;
%             polar(angle(crf(:,2)),abs(crf(:,2)),'r');
%             grid on;
    
    
      
      end
    
end


