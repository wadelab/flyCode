function [thisFlyData, success] = arw_read_arduino_file (fName)
%function [thisFlyData, success] = arw_read_arduino_file (fName, bplotFigure)
% This reads SSVEP data downloaded from the flyCode arduino; each fly is
% stimulated ~45 times, with blocks of 1024 intger data; each line contains
% time, stimulus, response
% This is followed by the contrast applied; each contrast line should begin
% with -99
% It returns the rawdata, the computed FFTs, the averaged CRF for this fly,
% the stimulus conditions, all in "thisFlyData" It also returns a boolean
% "success" to say if the file was successfully read.
% ARW modified lightly from CE code to remove plotting

success = true ;
thisFlyData.Error = 'None' ;
%sExt = getPictExt () ;
bCloseGraphs = true ;

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


if (strfind(line1a, 'GET /?'))
    line1a = line1a(1:strfind(line1a, "HTTP")-2);
    line1b=strrep(line1a, 'GET /?'  ,'');
    % will return line as cell array
    lineSaved = strsplit(line1b, '&');
    line = lineSaved ;
else
    %newer code
    line1b=strrep(line1a, 'GET /'  ,'');
    % will return line as cell array
    lineSaved = strsplit(line1b, ',');
    line = lineSaved ;
end

% find and delete the filename
ix = strfind(line, 'filename=') ;
ix = find(~cellfun(@isempty,ix));
if (isempty(ix))
    thisFlyData.Error = ['Not a proper SVP file: ', fName]
    success = false ;
    return
end
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
    %     %% try to read the file as compressed
    [fid, msg] = fopen(fName, 'rt');
    %line1a = fgets(fid)
    %original code was 132; later was extended to 135
    A1 = fread(fid,[1,132],'uint8') ; %read this and throw it away as we've already read this

    %allocate memory for the data
    alldata = zeros (1025*45, 3) ;

    try
        for i = 0 : 44
            alldata ((i*1025)+1:(i*1025)+1025, 3) = fread(fid,[1,1025],'int32','ieee-le') ; %  block of ergs
            alldata ((i*1025)+1:(i*1025)+1025, 1) = fread(fid,[1,1025],'int32','ieee-le') ; %  block of time_data
            alldata ((i*1025)+1025,2) = alldata ((i*1025)+1025,1) ;
        end
        fclose(fid);

        %%
    catch
        thisFlyData.Error = ['Binary Read function died with - file too small : ', fName];
        disp(thisFlyData.Error);
        success = false ;
        return
    end
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

m = nSamples / nContrasts;
ymax = max(alldata(:,3)) ;
ymin = min(alldata(:,3)) ;

rawdata=zeros(nSamples,1024);
stimdata=zeros(nSamples,1024);
for i = 1:nSamples

    rawdata(i,:)=alldata(iStart:iEnd,3) ;
    stimdata(i,:)=alldata(iStart:iEnd,2) * 4 - 400  ; % stimdata only used for plotting
    contrasts(i,:) = alldata(iEnd+1,:) ;

    iStart = iStart + 1025;
    iEnd = iEnd + 1025;
end;

%%  do fft
fft_display_limit = 250 ;
complex_fftData= zeros(nSamples,1000);
for i = 1:nSamples
    % limit it to 1 sec worth of data?
    complex_fftData(i,:)=fft(rawdata(i,1:1000)) /1000; %% return this to main program and then average first and then calculate the abs
end

% ignore dc component on complex fft
complex_fftData (:,1) = 0;


%% Sort the data
% calculate the sorted array; we count the zeros in the first column...
[dummy_CRF, sortindex] = sortrows(fliplr(contrasts));

thisFlyData.sortedContrasts = zeros(size(contrasts)) ;
thisFlyData.sortedContrasts = contrasts( sortindex,:);

% sort the rawdata, stimdata and fft to go with the CRFs
thisFlyData.sortedRawData = zeros(size(rawdata)) ;
thisFlyData.sortedRawData( [1:nSamples],: ) = rawdata(sortindex,:);

% sort the rawdata and fft to go with the CRFs
thisFlyData.sortedStimData = zeros(size(rawdata)) ;
thisFlyData.sortedStimData( [1:nSamples],: ) = stimdata(sortindex,:);

thisFlyData.sortedComplex_FFTdata = zeros(size(complex_fftData)) ;
thisFlyData.sortedComplex_FFTdata( [1:nSamples],: ) = complex_fftData(sortindex,:);

%% calculate and plot mean FFT
%%FIXME sort out all these constants...

thisFlyData.meanFFT=zeros(nContrasts,240);
thisFlyData.meanContrasts=zeros(nContrasts,3);

for i = 1 : nContrasts

    RPT = 5*(i-1) + 1 ;

    % to extract just some repeats alter code here;
    % don't add more than 4 [5 repeats, inclusive counting]
    % eg to ignore 1st round
    % startRPT = RPT + 1
    startRPT = RPT + 1 ;
    end_RPT = RPT + 4 ; % RPT ;
    %find mean

    meanFFT = mean(thisFlyData.sortedComplex_FFTdata(startRPT:end_RPT,1:240),1) ;
    thisFlyData.meanFFT(i,:) = meanFFT;
    thisFlyData.meanContrasts(i,:) = thisFlyData.sortedContrasts(RPT,:);
end

