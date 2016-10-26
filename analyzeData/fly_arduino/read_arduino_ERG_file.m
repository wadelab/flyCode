%%read_arduino_ERG
function [success,lineSaved] = read_arduino_ERG_file (fName, do_fft);


[pathstr, fileName, ext] = fileparts(fName) ;

%% read header line
[fid, msg] = fopen(fName, 'rt');
line1a = fgets(fid);
fclose(fid);

if (strfind(line1a, 'GET /?'))
    line1b=strrep(line1a, 'GET /?'  ,'');
    line1c=strrep(line1b, 'HTTP/1.1','');
    
    % will return line as cell array
    lineSaved = strsplit(line1c, '&');
    line = lineSaved ;
else
    %newer code
    line1b=strrep(line1a, 'GET /'  ,'');
    line1c=strrep(line1b, 'HTTP/1.1','');
    
    % will return line as cell array
    lineSaved = strsplit(line1c, ',');
    line = lineSaved ;
end

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
if (nContrasts ~= 5)
    thisFlyData.Error = ['Not exactly 5 contrasts in file : ', fName]
    success = false ;
    return
end

if (mod(nContrasts,1) ~= 0)
    thisFlyData.Error = ['Not exactly 1024 data lines in file : ', fName]
    success = false ;
    return
end

timedata = alldata(1:1024,1);
timedata = timedata - timedata(1);


iStart = 1;
iEnd = 1024;
xdata = linspace(1,250);

%% test if figure exists, if so close it
if ~isempty(findall(0,'Type','Figure'))
    close;
end
%%

figure ('Name', strcat('Data from: ',fileName));

ymax = 1500 ; %max(alldata(:,3)) ;
ymin = -2000 ; %min(alldata(:,3)) ;

rawdata=zeros(nContrasts,1024);
for i = 1:nContrasts
    
    rawdata(i,:)=alldata(iStart:iEnd,3) ;
    % contrasts(i,:) = alldata(iEnd+1,:) ;
    
    %now we've read the data, lets plot it
    if (do_fft)
        subplot(nContrasts +1, 3, (i*3)-2);
    else
        subplot(3, 2, i);
    end
    plot (timedata, rawdata(i,:));
    axis([0 timedata(1024) ymin ymax]);
    
    yTxt = strcat(num2str(i), '//') ;
    ylabel(yTxt);
    
    if (i==1)
        line1d = strrep(line1c, '&',' ');
        line1e = strrep(line1d, '_',' ');
        text(-500,ymax*1.2,line1e);
    end
    
    if (do_fft)
        fft1=abs(fft(rawdata(i,1:200)));
        subplot(nContrasts +1, 3, (i*3)-1);
        plot (xdata, fft1(1:100));
        
        fft2=abs(fft(rawdata(i,350:670)));
        subplot(nContrasts +1, 3, (i*3));
        plot (xdata, fft2(1:100));
    end
    
    iStart = iStart + 1025;
    iEnd = iEnd + 1025;
end;
xTxt = 'scales are in ms, Hz';
xlabel(xTxt);
if (do_fft)
    subplot(nContrasts +1 ,1, nContrasts +1);
else
    subplot(3, 2, 6);
end ;
meandata = mean(rawdata);
plot (timedata, meandata);
axis([0 timedata(1024) ymin ymax]);
ylabel('mean');

%% is it too noisy ?
myNoise = std(meandata(1:300));
% if (myNoise > 100)
%     success = false ;
%     set(gcf,'Color','red');
% end
%%
sExt = getPictExt ();
printFilename = [pathstr, filesep, fileName, '_MyData', sExt];
print( '-dpsc', printFilename );

% %% not sure this is the best discriminat
% if (myNoise > 100)
%     return 
% end
    

%% get some data out
disp('mean ERG:');
lineSaved = [lineSaved, {['nRepeats =',num2str(nContrasts  )]}];
lineSaved = [lineSaved, {['max =',     num2str(max(meandata))]}];
lineSaved = [lineSaved, {['min =',     num2str(min(meandata))]}];
lineSaved = [lineSaved, {['off-transient =', num2str(min(meandata(680:720))-mean(meandata(650:680)))]}];
lineSaved = [lineSaved, {['recovery =', num2str(max(meandata(720:820))-mean(meandata(650:680)))]}];
lineSaved = [lineSaved, {['on-transient =', num2str(max(meandata(300:380))-mean(meandata(300:340)))]}];
lineSaved = [lineSaved, {['peak-peak =', num2str(max(meandata)-min(meandata))]}];
lineSaved = [lineSaved, {['noise =', num2str(myNoise)]}];

%% calculate average every 10%
for i = 1:10
    k = (i-1)*100 + 1;
    lineSaved = [lineSaved, {[num2str((i-1)*10), '% =', num2str(mean(meandata(k:k+23)))]}];
end

%% write out line
for i = 1:length(lineSaved)
    disp(lineSaved{i});
end



success = true ;
return



