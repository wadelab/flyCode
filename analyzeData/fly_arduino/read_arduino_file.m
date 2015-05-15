

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

m = nSamples / nContrasts;


ymax = max(alldata(:,3)) ;
ymin = min(alldata(:,3)) ;

rawdata=zeros(nSamples,1024);
stimdata=zeros(nSamples,1024);
for i = 1:nSamples
    
    rawdata(i,:)=alldata(iStart:iEnd,3) ;
    stimdata(i,:)=alldata(iStart:iEnd,2) * 4 - 400  ; % stimdata only used for plotting
    contrasts(i,:) = alldata(iEnd+1,:) ;
    
    %now we've read the data, lets plot it
    subplot(m,nContrasts,i);
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
    subplot(m,nContrasts,i);
    bar(abs(complx_fftData(i,1:fft_display_limit)));
    axis([0 fft_display_limit 0 max_fft]); % plot to 25Hz
    set(gca,'XTickLabel',''); % no tick labels (unless bottom row, see below)
    
    yTxt = strcat(num2str(contrasts(i,2)), '//', num2str(contrasts(i,3))) ;
    ylabel(yTxt);
    
    if (i> (m-1)*nContrasts)
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
    RPT = 5*(i-1) + 1 ;
    
    % to extract just some repeats alter code here; 
    % don't add more than 4 [5 repeats, inclusive counting]
    % eg to ignore 1st round 
    % startRPT = RPT + 1
    startRPT = RPT ;
    end_RPT = RPT + 4 ;
    %find mean and plot it
    
    meanFFT = mean(thisFlyData.sortedComplex_FFTdata(startRPT:end_RPT,1:240)) ;
    bar(xScale,abs(meanFFT));
    axis([0 max(xScale) 0 max_fft]);
    
    yTxt = strcat(num2str(thisFlyData.sortedContrasts(RPT,2)), '//', num2str(thisFlyData.sortedContrasts(RPT,3))) ;
    ylabel(yTxt);
    
    thisFlyData.meanFFT(i,:) = meanFFT;
    thisFlyData.meanContrasts(i,:) = thisFlyData.sortedContrasts(RPT,:);
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

%% calculate + plot CRF for this fly...
complx_CRF = Calculate_CRF(thisFlyData.meanContrasts, thisFlyData.meanFFT);
plot_mean_crf (cellstr(fileName), complx_CRF,pathstr,fileName, bCloseGraphs);





