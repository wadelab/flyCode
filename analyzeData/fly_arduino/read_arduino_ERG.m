close all;
clear all;%%read_arduino_ERG

success = true ;

[f,p]=uigetfile('*.ERG');
fName=fullfile(p,f);
[pathstr, fileName, ext] = fileparts(fName) ;

%% read header line
[fid, msg] = fopen(fName, 'rt');
line1a = fgets(fid);
fclose(fid);
line1b=strrep(line1a, 'GET /?'  ,'');
line1c=strrep(line1b, 'HTTP/1.1','');

% will return line as cell array
lineSaved = strsplit(line1c, '&');
line = lineSaved ;

% find and delete the filename
ix = strfind(line, 'filename=') ;
ix = find(~cellfun(@isempty,ix));
thisFlyData.fileName = line{ix};
line (ix)=[];
thisFlyData.phenotypes = line ;



%% read the ERG data - 5 contrasts of 1024 data points
% each set of raw data followed by a line (which would be contrast data in
% SSVEP)

alldata = csvread(fName, 1,0);

[nContrasts,c] = size(alldata);
nContrasts= nContrasts/1025 ;
timedata = alldata(1:1024,1);
timedata = timedata - timedata(1);


iStart = 1;
iEnd = 1024;
xdata = linspace(1,250);

figure ('Name', strcat('Data from: ',fileName));

ymax = max(alldata(:,3)) ;
ymin = min(alldata(:,3)) ;

rawdata=zeros(nContrasts,1024);
for i = 1:nContrasts
    
    rawdata(i,:)=alldata(iStart:iEnd,3) ;
   % contrasts(i,:) = alldata(iEnd+1,:) ;
    
    %now we've read the data, lets plot it
    subplot(nContrasts +1, 3, (i*3)-2);
    plot (timedata, rawdata(i,:));
    axis([0 timedata(1024) ymin ymax]);
    
    yTxt = strcat(num2str(i), '//') ;
    ylabel(yTxt);
    
    fft1=abs(fft(rawdata(i,1:200)));
    subplot(nContrasts +1, 3, (i*3)-1);
    plot (xdata, fft1(1:100));
    
    fft2=abs(fft(rawdata(i,350:670)));
    subplot(nContrasts +1, 3, (i*3));
    plot (xdata, fft2(1:100));
    
    iStart = iStart + 1025;
    iEnd = iEnd + 1025;
end;

subplot(nContrasts +1 ,1, nContrasts +1);
meandata = mean(rawdata);
plot (timedata, meandata);
axis([0 timedata(1024) ymin ymax]);
ylabel('mean');

printFilename = [pathstr, filesep, fileName, '_MyData', '.eps'];
print( printFilename );

%% get some data out
disp('mean ERG:');
disp(['nRepeats =',num2str(nContrasts)]);
disp(['max =', num2str(max(meandata))]);
disp(['min =', num2str(min(meandata))]);
disp(['off-transient =', num2str(min(meandata(680:720))-mean(meandata(650:680)))]);

for i = 1:length(lineSaved)
   disp(lineSaved{i});
end 



