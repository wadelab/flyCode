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

% nContrasts = 0;
% cTmp = [1;2];
% while (cTmp (2) > cTmp(1))
%     nContrasts = nContrasts + 1;
%     cTmp = csvread(fName, nContrasts,0, [nContrasts,0,nContrasts+1,0]) ;
% end
% 
% contrasts=csvread(fName, 1,0, [1,0,nContrasts,2]);

%% read the SSVEP data - 9 contrasts of 1024 data points
alldata = csvread(fName, 1,0);

[nContrasts,c] = size(alldata);
nContrasts= nContrasts/1025 
timedata = alldata(1:1024,1);
timedata = timedata - timedata(1);


iStart = 1;
iEnd = 1024;

figure ('Name', strcat('Rawdata of: ',fileName));

        ymax = max(alldata(:,3)) ;
        ymin = min(alldata(:,3)) ;

rawdata=zeros(nContrasts,1024);
for i = 1:nContrasts
    
        rawdata(i,:)=alldata(iStart:iEnd,3) ;
        contrasts(i,:) = alldata(iEnd+1,:) ;
        
        %now we've read the data, lets plot it
        subplot(nContrasts +1 ,1,i);
        plot (timedata, rawdata(i,:));
        axis([0 timedata(1024) ymin ymax]);
        
         yTxt = strcat(num2str(i), '//') ;
         ylabel(yTxt);

        iStart = iStart + 1025;
        iEnd = iEnd + 1025;
end;

        subplot(nContrasts +1 ,1,nContrasts +1);
        plot (timedata, mean(rawdata));
        axis([0 timedata(1024) ymin ymax]);
        ylabel('mean');

printFilename = [pathstr, filesep, fileName, '_RawData', '.eps'];
print( printFilename );


