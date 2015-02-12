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
timestart= 300;
timend=500;
rawdata=zeros(nContrasts,1024);
for i = 1:nContrasts
    
    rawdata(i,:)=alldata(iStart:iEnd,3) ;
   % contrasts(i,:) = alldata(iEnd+1,:) ;
    
    %now we've read the data, lets plot it
    subplot( 2, 3, i);
    plot (timedata(timestart:timend), rawdata(i,timestart:timend));
    axis([timedata(timestart) timedata(timend) ymin ymax]);
    
    yTxt = strcat(num2str(i), '//') ;
    ylabel(yTxt);
    iStart = iStart + 1025;
    iEnd = iEnd + 1025;
end;
xTxt = 'scales are in ms, Hz';
xlabel(xTxt);

subplot( 2 ,3, 6);
meandata = mean(rawdata);
plot (timedata(timestart:timend), meandata(timestart:timend));
axis([timedata(timestart) timedata(timend) ymin ymax]);
ylabel('mean');

sExt = getPictExt ();
printFilename = [pathstr, filesep, fileName, '_MyData', sExt];
print( printFilename );

%% get some data out
disp('mean ERG:');
disp(['nRepeats =',num2str(nContrasts)]);
disp(['max =', num2str(max(meandata))]);
disp(['starting value=' , num2str(mean(meandata(1:20)))]);
disp(['min =', num2str(min(meandata))]);
disp(['off-transient =', num2str(min(meandata(680:720))-mean(meandata(650:680)))]);

%% show the values of the individual windows
for i = 1:nContrasts
    disp(['max ',num2str(i),' =', num2str(max(rawdata(i,:)))]);
disp(['starting value ',num2str(i),'=' , num2str(mean(rawdata(i,1:20)))]);
disp(['min ',num2str(i),' =', num2str(min(rawdata(i,:)))]);
disp(['off-transient ',num2str(i),' =', num2str(min(rawdata(i,680:720))-mean(rawdata(i,650:680)))]);
end


for i = 1:length(lineSaved)
   disp(lineSaved{i});
end 



