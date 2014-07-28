nContrasts = 9 ; %fixed for this fist version of the arduino stimuli

[f,p]=uigetfile('*.csv');
fName=fullfile(p,f);

%% read header line
fid = fopen(fName, 'rt');
line1a = fgets(fid);
fclose(fid);
line1b=strrep(line1a, 'GET /?'  ,'');
line1c=strrep(line1b, 'HTTP/1.1','');

line = strsplit(line1c, '&');


%% read the table of contrasts
contrasts=csvread(fName, 1,0, [1,0,nContrasts,2]);



%% read the SSVEP data - 9 contrasts of 1024 data points

r=zeros(nContrasts,1024);
for i = 0:nContrasts-1
    iStart = 10+1024*i
    iEnd = 1033+1024*i
    r(i+1,:)=csvread(fName, iStart,3, [iStart,3,iEnd,3]);
end;



%% subtract mean and do fft
figure();
for i = 1:nContrasts
    
    r(i,:)=r(i,:)-mean(r(i,:));
    subplot(9,1,i);
    fData=fft(r(i,:));
    bar(abs(fData(2:100)));
    axis([0 100 0 5000]);
    set(gca,'XTickLabel',''); % no tick labels (unless bottom row, see below)
    
    yTxt = strcat(num2str(contrasts(i,2)), '//', num2str(contrasts(i,3))) ;
    ylabel(yTxt);
    
end;
% label bottom row
set(gca,'XTickLabel',{'0',' ','5',' ','10',' ','15',' ','20',' ','25'});
    
xlabel('Hz');

