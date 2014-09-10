% close all
% clear all

function {myUNmaskedCRF  myMaskedCRF} = read_arduino_file (fName)

nContrasts = 9 ; %fixed for this first version of the arduino stimuli

% [f,p]=uigetfile('*.SVP');
% fName=fullfile(p,f);
[pathstr, fileName, ext] = fileparts(fName) ; 

%% read header line
[fid, msg] = fopen(fName, 'rt');
line1a = fgets(fid);
fclose(fid);
line1b=strrep(line1a, 'GET /?'  ,'');
line1c=strrep(line1b, 'HTTP/1.1','');

line = strsplit(line1c, '&');
 

%% read the table of contrasts
contrasts=csvread(fName, 1,0, [1,0,nContrasts,2]);



%% read the SSVEP data - 9 contrasts of 1024 data points
timedata = csvread(fName, 10,1, [10,1,1033,1]);
figure ('Name', strcat('Rawdata of: ',fileName));


rawdata=zeros(nContrasts,1024);
for i = 1:nContrasts
    iStart = 10+1024*(i-1) ;
    iEnd = 1033+1024*(i-1) ;
    rawdata(i,:)=csvread(fName, iStart,3, [iStart,3,iEnd,3]);

    %now we've read the data, lets plot it
    subplot(nContrasts,1,i);
    plot (timedata, rawdata(i,:));
    
    yTxt = strcat(num2str(contrasts(i,2)), '//', num2str(contrasts(i,3))) ;
    ylabel(yTxt);
end;



%% subtract mean and do fft
fft_display_limit = 100 ;
figure('Name', strcat('FFT of: ',fileName));
fftData= zeros(nContrasts,fft_display_limit);
for i = 1:nContrasts
    
    rawdata(i,:)=rawdata(i,:)-mean(rawdata(i,:));
    subplot(nContrasts,1,i);
    complx_fftData=fft(rawdata(i,:)); %% return this to main program and then average first and then calculate the abs
%%%%%s    take angle too
    fftData(i,:) = abs(complx_fftData(2:fft_display_limit+1));
    bar(fftData(i,:));
    axis([0 fft_display_limit 0 10000]); % plot to 25Hz
    set(gca,'XTickLabel',''); % no tick labels (unless bottom row, see below)
    
    yTxt = strcat(num2str(contrasts(i,2)), '//', num2str(contrasts(i,3))) ;
    ylabel(yTxt);
    
end;
% label bottom row
set(gca,'XTickLabel',{'0',' ','5',' ','10',' ','15',' ','20',' ','25'});
xlabel('Hz');

%% Plot 12 Hz CRF for this fly
figure('Name', strcat('12 Hz CRF of: ',fileName));

xData = contrasts(:,2);
y12Data = fftData(:,49); %%%%%%%%%%%%%%%%%%%%%%%%%%% ???????????????????????????? should this be 50 ?
%y15Data = fftData(:,max(60:63));

%plot(xData, y12Data, 'LineStyle','none', 'marker', 'o');

%% Sort the data
CRF=zeros(nContrasts,3);

CRF(:,1)= contrasts(:,3);
CRF(:,2)= contrasts(:,2);
CRF(:,3)= y12Data;
%plot (CRF([1 5],1), CRF([1 5],3), '*');
%%
%     mask %    contrast   12Hz response
%          0    0.0050    0.3238
%          0    0.0100    1.0243
%          0    0.0300    2.1318
%          0    0.0700    4.1068
%          0    0.1000    4.4882
%     0.0300    0.0050    0.8195
%     0.0300    0.0100    0.9711
%     0.0300    0.0300    3.0109
%     0.0300    0.0700    4.0892

% return the sorted array; we should count the zeros in the fist column...
myCRF = sortrows(CRF);
myUNmaskedCRF = myCRF([1:5],:);
myMaskedCRF = myCRF([6:nContrasts],:);

plot (myUNmaskedCRF(:,2), myUNmaskedCRF(:,3), '-*', myMaskedCRF(:,2), myMaskedCRF(:,3), '-.O' );
legend('UNmasked', 'Masked') ;
set(gca,'XScale','log');

% CRF(:,3) has dat for this fly run




