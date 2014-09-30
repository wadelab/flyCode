% close all
% clear all

function [thisFlyData, success] = read_arduino_file (fName, bCloseGraphs)

success = true ;

% [f,p]=uigetfile('*.SVP');
% fName=fullfile(p,f);
[pathstr, fileName, ext] = fileparts(fName) ;

%% read header line
[fid, msg] = fopen(fName, 'rt');
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
thisFlyData.phenotypes = line ;
%% 

%%default values
F1=12 ; %Hz
F2=15 ; %Hz

F1_index = strmatch('F1',line);
ff= strsplit(line{F1_index},'=');
num = sscanf(ff{length(ff)}, '%f');
if ~isempty(num)
    F1 = num;
    end
thisFlyData.F1=F1;

F2_index = strmatch('F2',line);
ff= strsplit(line{F2_index},'=');
num = sscanf(ff{length(ff)}, '%f');
if ~isempty(num)
    F2 = num;
    end
thisFlyData.F2=F2;

%% count the contrasts and then read the table of contrasts
% zero based array!
% GET /?GAL4=TH&UAS=G2019S&Age=1&sex=female&organism=fly&colour=blue&filename=18_08_13h46m05 HTTP/1.1
% 0,       5.00,      30.00
% 1,       5.00,       0.00
% 2,      70.00,       0.00
% 3,      30.00,       0.00
% 4,      70.00,      30.00
% 5,      10.00,      30.00
% 6,      30.00,      30.00
% 7,     100.00,       0.00
% 8,      10.00,       0.00
% 0, 0, 142, 0
% 1, 4, 156, 0
% 2, 8, 166, 0
% 3, 12, 170, 0
% read LH column one by one and look for decreased value when ERG data starts

nContrasts = 0;
cTmp = [1;2];
while (cTmp (2) > cTmp(1))
    nContrasts = nContrasts + 1;
    cTmp = csvread(fName, nContrasts,0, [nContrasts,0,nContrasts+1,0]) ;
end

contrasts=csvread(fName, 1,0, [1,0,nContrasts,2]);

%% read the SSVEP data - 9 contrasts of 1024 data points
timedata = csvread(fName, 10,1, [10,1,1033,1]);

figure ('Name', strcat('Rawdata of: ',fileName));
rawdata=zeros(nContrasts,1024);
for i = 1:nContrasts
    iStart = 10+1024*(i-1) ;
    iEnd = 1033+1024*(i-1) ;
    try
        rawdata(i,:)=csvread(fName, iStart,3, [iStart,3,iEnd,3]);
        
        %now we've read the data, lets plot it
        subplot(nContrasts,1,i);
        plot (timedata, rawdata(i,:));
        
        yTxt = strcat(num2str(contrasts(i,2)), '//', num2str(contrasts(i,3))) ;
        ylabel(yTxt);
    catch
        success = false ;
        disp([' File Read failed ', fileName, ' Bad format ? Out of data ?']);
        if (bCloseGraphs)
            delete(gcf) ;
        end
        return ;
    end
end;
printFilename = [pathstr, filesep, fileName, '_RawData', '.eps'];
print( printFilename );
if (bCloseGraphs)
    delete(gcf) ;
end


%% subtract mean and do fft
fft_display_limit = 250 ;

figure('Name', strcat('FFT of: ',fileName));
fftData= zeros(nContrasts,fft_display_limit);
for i = 1:nContrasts
    
    rawdata(i,:)=rawdata(i,:)-mean(rawdata(i,:));
    subplot(nContrasts,1,i);
    complx_fftData(i,:)=fft(rawdata(i,:)); %% return this to main program and then average first and then calculate the abs
    %%%%%s    take angle too
    fftData(i,:) = abs(complx_fftData(i,2:fft_display_limit+1));
    bar(fftData(i,:));
    axis([0 fft_display_limit 0 2000]); % plot to 25Hz
    set(gca,'XTickLabel',''); % no tick labels (unless bottom row, see below)
    
    yTxt = strcat(num2str(contrasts(i,2)), '//', num2str(contrasts(i,3))) ;
    ylabel(yTxt);
    
end;
% label bottom row
set(gca,'XTickLabel',{'0','12.5','25','37.5','50','62.5'});
xlabel('Hz');

printFilename = [pathstr, filesep, fileName, '_FFT', '.eps'];
print( printFilename );
if (bCloseGraphs)
    delete(gcf) ;
end


%% Extract fft data
% sample rate was 4 ms, so these numbers are 4 times
FreqNames = {'1F1', '1F2', '2F1', '2F2', '1F1+1F2', '2F2+2F2', 'F2-F1' };
FreqsToExtract = [ F1, F2, 2*F1, 2*F2, F1+F2, 2*(F1+F2), F2-F1 ];
FreqsToExtract = FreqsToExtract*4 + 1 ;
% this next bit might be written more cleanly, but i want to check we get
% the right section..
y12Data = fftData(:,FreqsToExtract(1));
y15Data = fftData(:,FreqsToExtract(2));
y24Data = fftData(:,FreqsToExtract(3));
y30Data = fftData(:,FreqsToExtract(4));
y27Data = fftData(:,FreqsToExtract(5));
y54Data = fftData(:,FreqsToExtract(6));
y03Data = fftData(:,FreqsToExtract(7));


CRF=zeros(nContrasts,5);

CRF(:,1)= contrasts(:,3);
CRF(:,2)= contrasts(:,2);
CRF(:,3)= y12Data;
CRF(:,4)= y15Data;
CRF(:,5)= y24Data;
CRF(:,6)= y30Data;
CRF(:,7)= y27Data;
CRF(:,8)= y54Data;
CRF(:,9)= y03Data;

%% Sort the data
% calculate the sorted array; we count the zeros in the first column...
[CRF, sortindex] = sortrows(CRF);

% sort the rawdata and fft to go with the CRFs
thisFlyData.sortedRawData = zeros(size(rawdata)) ;
thisFlyData.sortedRawData( [1:nContrasts],: ) = rawdata(sortindex,:);

thisFlyData.sortedComplex_FFTdata = zeros(size(complx_fftData)) ;
thisFlyData.sortedComplex_FFTdata( [1:nContrasts],: ) = complx_fftData(sortindex,:);



%% calculate the mean for each contrast
c12 = CRF(:,[1:2]);

i = 1;
k = 1;
while (i <= nContrasts)
  j = i + 1;
  while (j <= nContrasts && isequal(c12(i,:), c12(j,:)))
     %disp ([i, '  ' ,j]);
     j = j + 1;
     end;

   av_CRF(k,:) = mean(CRF(i:j-1,:),1)  ; % need the ,1 to force it to work if i==j
   
   
   k = k + 1 ;
   i = j ;
end



% how many unmasked contrasts were given
nUnMasked = sum(av_CRF(:,1)==0) ;
[nContrasts,c] = size(av_CRF);

%return the data
thisFlyData.sorted_CRF = av_CRF;
thisFlyData.nUnMasked = nUnMasked ;



% figure('Name','Sanity check');
% for i = 1:nContrasts
% 
%     subplot(nContrasts,1,i);
%     plot (timedata, thisFlyData.sortedRawData(i,:));
%     %bar(sortedFFTdata(i,:));
% 
% end;
%%


%success = ( nUnMasked < 6 );
%success = strfind(fName, 'a.');


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
    plot (av_CRF([1:nUnMasked],2), av_CRF([1:nUnMasked],3), '-*', av_CRF([nUnMasked+1:nContrasts],2), av_CRF([nUnMasked+1:nContrasts],3), '-.O' );
    legend('UNmasked', 'Masked', 'Location', 'NorthWest') ;
    set(gca,'XScale','log');
    
    printFilename = [pathstr, filesep, fileName, '_', FreqNames{1}, '_CRF', '.eps'];
    print( printFilename );
    if (bCloseGraphs)
        delete(gcf) ;
    end
    
    %% Plot 24 Hz av_CRF for this fly
    
    figure('Name', strcat('2F1 Hz av_CRF of: ',fileName));
    plot (av_CRF([1:nUnMasked],2), av_CRF([1:nUnMasked],5), '-*', av_CRF([nUnMasked+1:nContrasts],2), av_CRF([nUnMasked+1:nContrasts],5), '-.O' );
    legend('UNmasked', 'Masked', 'Location', 'NorthWest') ;
    set(gca,'XScale','log');
    
    printFilename = [pathstr, filesep, fileName, '_', FreqNames{3}, '_CRF', '.eps'];
    print( printFilename );
    if (bCloseGraphs)
        delete(gcf) ;
    end
    
else
    disp (['File not ok: ', fileName, ' *************************']);
end

