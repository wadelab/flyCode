% close all
% clear all

function myCRF = read_arduino_file (fName)

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

rawdata=zeros(nContrasts,1024);
for i = 0:nContrasts-1
    iStart = 10+1024*i ;
    iEnd = 1033+1024*i ;
    rawdata(i+1,:)=csvread(fName, iStart,3, [iStart,3,iEnd,3]);
end;



%% subtract mean and do fft
figure('Name', strcat('FFT of: ',fileName));
fftData= zeros(nContrasts,99);
for i = 1:nContrasts
    
    rawdata(i,:)=rawdata(i,:)-mean(rawdata(i,:));
    subplot(9,1,i);
    complx_fftData=fft(rawdata(i,:)); %% return this to main program and then average first and then calculate the abs
%%%%%s    take angle too
    fftData(i,:) = abs(complx_fftData(2:100));
    bar(fftData(i,:));
    axis([0 100 0 1000]); % plot to 25Hz
    set(gca,'XTickLabel',''); % no tick labels (unless bottom row, see below)
    
    yTxt = strcat(num2str(contrasts(i,2)), '//', num2str(contrasts(i,3))) ;
    ylabel(yTxt);
    
end;
% label bottom row
set(gca,'XTickLabel',{'0',' ','5',' ','10',' ','15',' ','20',' ','25'});
xlabel('Hz');

%% Plot CRF for this fly
figure('Name', strcat('CRF of: ',fileName));

xData = contrasts(:,2);
y12Data = fftData(:,50);
%y15Data = fftData(:,max(60:63));

plot(xData, y12Data, 'LineStyle','none', 'marker', 'o');

%% Sort the data
CRF=zeros(nContrasts,3);

CRF(:,1:2)= contrasts(:,2:3);
CRF(:,3)= y12Data;
plot (CRF(:,1), CRF(:,3), '*');
% return the sorted array
myCRF = sortrows(CRF);



% CRF(:,3) has dat for this fly run




