

function [thisFlyData, success] = read_arduino_file (fName, bCloseGraphs)
% This reads SSVEP data downloaded from the flyCode arduino; each fly is
% stimulated ~45 times, with blocks of 1024 intger data; each line contains
% time, stimulus, response
% This is followed by the contrast applied; each contrast line should begin
% with -99
% It returns the rawdata, the computed FFTs, the averaged CRF for this fly,
% the stimulus conditions, all in "thisFlyData" It also returns a boolean
% "success" to say if the file was successfully read.
% Input parameters are the filename and a boolean to say if the graphs
% should be closed at the end of the code

success = true ;
thisFlyData.Error = 'None' ;
sExt = getPictExt () ;

% [f,p]=uigetfile('*.SVP');
% fName=fullfile(p,f);
[pathstr, fileName, ext] = fileparts(fName) ;

%% read header line
[fid, msg] = fopen(fName, 'rt');
% if we succeed fid > 2
if (fid < 3)
    thisFlyData.Error = ['Could not open file: ', fName]
    success = false ;
    return
end

line1a = fgets(fid);
fclose(fid);
line1b=strrep(line1a, 'GET /?'  ,'');
line1c=strrep(line1b, 'HTTP/1.1','');

% will return line as cell array
line = strsplit(line1c, '&');

% find and delete the filename
ix = strfind(line, 'filename=') ;
ix = find(~cellfun(@isempty,ix));
thisFlyData.fileName = line{ix};
line (ix)=[];

%%

%%default values
F1=12 ; %Hz
F2=15 ; %Hz

F1_index = strmatch('F1',line);
ff= strsplit(line{F1_index},'=');
num = sscanf(ff{length(ff)}, '%f');
if ~isempty(num)
    F1 = num;
    line (F1_index)=[];
end
thisFlyData.F1=F1;

F2_index = strmatch('F2',line);
ff= strsplit(line{F2_index},'=');
num = sscanf(ff{length(ff)}, '%f');
if ~isempty(num)
    F2 = num;
    line (F2_index)=[];
end
thisFlyData.F2=F2;

thisFlyData.phenotypes = line ;


%% read the SSVEP data - 9 contrasts of 1024 data points
% followed by line of contrast
try
    alldata = csvread(fName, 1,0);
catch
    thisFlyData.Error = ['CSVfunction died with unknown error in file : ', fName];
    disp(thisFlyData.Error);
    success = false ;
    return
end
[nSamples,c] = size(alldata);

if (c < 3)
    thisFlyData.Error = ['Less than 3 columns found in file : ', fName];
    disp(thisFlyData.Error);
    success = false ;
    return
end

if (nSamples < 1025)
    thisFlyData.Error = ['Less than 1024 data lines found in file : ', fName];
    disp(thisFlyData.Error);
    success = false ;
    return
end

nSamples= nSamples/1025;
if (mod(nSamples,1) ~= 0)
    thisFlyData.Error = ['Not exactly 1024 data lines in each block of the file : ', fName];
    disp(thisFlyData.Error);
    success = false ;
    return
end

nReqContrasts = 45;
if (nSamples ~= nReqContrasts)
    thisFlyData.Error = ['Not exactly ', num2str(nReqContrasts), ' contrasts in file : ', fName];
    disp(thisFlyData.Error);
    success = false ;
    return
end



timedata = alldata(1:1024,1);
timedata = timedata - timedata(1);

%% These constants are fixed 
nContrasts = 9;
iStart = 1;
iEnd = 1024;

%% plot raw data
figure ('Name', strcat('Rawdata of: ',fileName));
n = nContrasts;
m = nSamples / n;


ymax = max(alldata(:,3)) ;
ymin = min(alldata(:,3)) ;

rawdata=zeros(nSamples,1024);
stimdata=zeros(nSamples,1024);
for i = 1:nSamples
    
    rawdata(i,:)=alldata(iStart:iEnd,3) ;
    stimdata(i,:)=alldata(iStart:iEnd,2) * 4 - 400  ; % stimdata only used for plotting
    contrasts(i,:) = alldata(iEnd+1,:) ;
    
    %now we've read the data, lets plot it
    subplot(m,n,i);
    plot ( timedata, rawdata(i,:), timedata, stimdata(i,:));
    axis([0 4092 ymin ymax]);
    
    yTxt = strcat(num2str(contrasts(i,2)), '//', num2str(contrasts(i,3))) ;
    ylabel(yTxt);
    
    iStart = iStart + 1025;
    iEnd = iEnd + 1025;
end;
xlabel('xscale is in ms');


printFilename = [pathstr, filesep, fileName, '_RawData', sExt];
h=gcf;
set(h,'PaperOrientation','landscape');
set(h,'PaperUnits','normalized');
set(h,'PaperPosition', [0 0 1 1]);
print( printFilename );
if (bCloseGraphs)
    delete(gcf) ;
end


%%  do fft
fft_display_limit = 250 ;
complx_fftData= zeros(nSamples,1000);
for i = 1:nSamples
    rawdata(i,:)=rawdata(i,:)-mean(rawdata(i,:));
    % limit it to 1 sec worth of data
    complx_fftData(i,:)=fft(rawdata(i,1:1000)); %% return this to main program and then average first and then calculate the abs
end
% ignore dc component on complex fft 
complx_fftData (:,1) = [];


%% plot fft
figure('Name', strcat('FFT of: ',fileName));
max_fft = max(max(abs(complx_fftData)));
for i = 1:nSamples
    subplot(m,n,i);
    bar(abs(complx_fftData(i,1:fft_display_limit)));
    axis([0 fft_display_limit 0 max_fft]); % plot to 25Hz
    set(gca,'XTickLabel',''); % no tick labels (unless bottom row, see below)
    
    yTxt = strcat(num2str(contrasts(i,2)), '//', num2str(contrasts(i,3))) ;
    ylabel(yTxt);
    
    if (i> (m-1)*n)
        % label bottom row
        set(gca,'XTickmode','manual');
        set(gca,'XTick',[0,12.5,25,37.5,50,62.5]*4);
        set(gca,'XTickLabel',{'0','12.5','25','37.5','50','62.5'});
        
    end ;
end;
xlabel('xscale is in Hz');

printFilename = [pathstr, filesep, fileName, '_FFT', sExt];
h=gcf;
set(h,'PaperOrientation','landscape');
set(h,'PaperUnits','normalized');
set(h,'PaperPosition', [0 0 1 1]);
print( printFilename );

if (bCloseGraphs)
    delete(gcf) ;
end





%% Sort the data
% calculate the sorted array; we count the zeros in the first column...
[dummy_CRF, sortindex] = sortrows(fliplr(contrasts));

thisFlyData.sortedContrasts = zeros(size(contrasts)) ;
thisFlyData.sortedContrasts = contrasts( sortindex,:); 

% sort the rawdata and fft to go with the CRFs
thisFlyData.sortedRawData = zeros(size(rawdata)) ;
thisFlyData.sortedRawData( [1:nSamples],: ) = rawdata(sortindex,:);

thisFlyData.sortedComplex_FFTdata = zeros(size(complx_fftData)) ;
thisFlyData.sortedComplex_FFTdata( [1:nSamples],: ) = complx_fftData(sortindex,:);

%% calculate and plot mean FFT
%%FIXME sort out all these constants...

thisFlyData.meanFFT=zeros(nContrasts,240);
thisFlyData.meanContrasts=zeros(nContrasts,3);

figure('Name', strcat('Mean FFT of: ',fileName));
xScale=0.25:0.25:60 ;
for i = 1 : nContrasts
    subplot(3,3,i);
    j = 5*(i-1) + 1 ;
    %find mean and plot it
    meanFFT = mean(thisFlyData.sortedComplex_FFTdata(j:j+4,1:240)) ;
    bar(xScale,abs(meanFFT));
    axis([0 max(xScale) 0 max_fft]);
    
    yTxt = strcat(num2str(thisFlyData.sortedContrasts(j,2)), '//', num2str(thisFlyData.sortedContrasts(j,3))) ;
    ylabel(yTxt);
    
    thisFlyData.meanFFT(i,:) = meanFFT;
    thisFlyData.meanContrasts(i,:) = thisFlyData.sortedContrasts(j,:);
end

xlabel('xscale is in Hz');

printFilename = [pathstr, filesep, fileName, '_mean_FFT', sExt];
h=gcf;
set(h,'PaperOrientation','landscape');
set(h,'PaperUnits','normalized');
set(h,'PaperPosition', [0 0 1 1]);
print( printFilename );

if (bCloseGraphs)
    delete(gcf) ;
end

%% Extract fft data
% sample rate was 4 ms, so these numbers are 4 times
FreqNames = GetFreqNames();
% FreqsToExtract = [ F1, F2, 2*F1, 2*F2, F1+F2, 2*(F1+F2), F2-F1 ];
% FreqsToExtract = FreqsToExtract*4 + 1 ;
% this next bit might be written more cleanly, but i want to check we get
% the right section..
FreqsToExtract = [48,60,96,120,108,216,12] ;
[dummy, nFreqs ] = size(FreqsToExtract);

complx_CRF=zeros(9,nFreqs+2);

complx_CRF(:,1)= thisFlyData.meanContrasts(:,3);
complx_CRF(:,2)= thisFlyData.meanContrasts(:,2);

for i = 1 : nFreqs
complx_CRF(:,i+2)= thisFlyData.meanFFT(:,FreqsToExtract(i));
end 

%[theta_CRF,abs_CRF] = cart2pol(real(complx_CRF(:,:)), imag(complx_CRF(:,:)))
theta_CRF=angle(complx_CRF);
abs_CRF = abs(complx_CRF);

% how many unmasked contrasts were given
nUnMasked = sum(abs_CRF(:,1)==0) ;


%return the data
thisFlyData.nUnMasked = nUnMasked ;


%% everything here is a plot so we get pictures in the directory where the file was
if (success)
    disp (['File ok: ', fileName])
    
    %     mask %    contrast   12Hz  & 15 Hz       24  &   30 Hz      F1+F2    2F1_2F2 response
    %          0    0.0050    0.7000    0.1192    0.0682    0.1184    0.0602    0.0088
    %          0    0.0100    1.1445    0.1962    0.0290    0.0976    0.0798    0.1139
    %          0    0.0300    3.4122    0.0642    0.1332    0.0834    0.1172    0.1681
    %          0    0.0700    7.7857    0.0965    0.3987    0.0752    0.1233    0.1432
    %          0    0.1000    9.8932    0.1163    0.5891    0.1674    0.2707    0.0640
    %     0.0300    0.0050    0.4410    2.4871    0.1067    0.1131    0.1026    0.0233
    %     0.0300    0.0100    0.9691    2.4725    0.1457    0.2365    0.1073    0.1004
    %     0.0300    0.0300    3.3535    2.5891    0.0647    0.1302    0.1800    0.0678
    %     0.0300    0.0700    6.8394    2.6980    0.2947    0.1872    0.5111    0.131
    
    
    
    %% Plot 12 Hz CRF for this fly
    
    figure('Name', strcat('1F1 Hz CRF of: ',fileName));
    subplot(1,2,1);
    plot (abs_CRF([1:nUnMasked],2), abs_CRF([1:nUnMasked],3), '-*', abs_CRF([nUnMasked+1:nContrasts],2), abs_CRF([nUnMasked+1:nContrasts],3), '-.Om' );
    legend('UNmasked', 'Masked', 'Location', 'NorthWest') ;
    set(gca,'XScale','log');
    
    xlabel('contrast (%)');
    ylabel('response, a.u.');
    
    subplot(1,2,2);
    %[t,r] = cart2pol(real(complx_CRF(:,3)), imag(complx_CRF(:,3)));
    polar (theta_CRF(1:nUnMasked,3),abs_CRF(1:nUnMasked,3), '-*');
    hold on ;
    polar (theta_CRF(nUnMasked+1:end,3),abs_CRF(nUnMasked+1:end,3), '--Om');
    hold off; 
    
    
    printFilename = [pathstr, filesep, fileName, '_', FreqNames{1}, '_CRF', sExt];
    h=gcf;
    set(h,'PaperOrientation','landscape');
    set(h,'PaperUnits','normalized');
    set(h,'PaperPosition', [0 0 1 1]);
    print( printFilename );
    if (bCloseGraphs)
        delete(gcf) ;
    end
    
    %% Plot 24 Hz av_CRF for this fly
    
    figure('Name', strcat('2F1 Hz av_CRF of: ',fileName));
    subplot(1,2,1);
    plot (abs_CRF([1:nUnMasked],2), abs_CRF([1:nUnMasked],5), '-*', abs_CRF([nUnMasked+1:nContrasts],2), abs_CRF([nUnMasked+1:nContrasts],5), '-.Om' );
    legend('UNmasked', 'Masked', 'Location', 'NorthWest') ;
    set(gca,'XScale','log');
    
    xlabel('contrast (%)');
    ylabel('response, a.u.');
    
    subplot(1,2,2);
    %[t,r] = cart2pol(real(complx_CRF(:,5)), imag(complx_CRF(:,5)));
    polar (theta_CRF(1:nUnMasked,5),abs_CRF(1:nUnMasked,5), '-*');
    hold on ;
    polar (theta_CRF(nUnMasked+1:end,5),abs_CRF(nUnMasked+1:end,5), '--Om');
    hold off; 
    
    
    printFilename = [pathstr, filesep, fileName, '_', FreqNames{3}, '_CRF', sExt];
    print( printFilename );
    if (bCloseGraphs)
        delete(gcf) ;
    end
    
else
    disp (['File not ok: ', fileName, ' *************************']);
end

