%%read_arduino_ERG
function [success,lineSaved] = read_arduino_ERG_file (fName, do_fft);


[pathstr, fileName, ext] = fileparts(fName) ;

%% read header line
[fid, msg] = fopen(fName, 'rt');
line1a = fgets(fid);
fclose(fid);

ss = size(strfind(line1a, 'GET')) ;
if ss(1) < 1
    thisFlyData.Error = ['Not a web URL : ', fName]
    success = false ;
    lineSaved = line1a ;
    return
    
end
    
if (strfind(line1a, 'GET /?'))
    line1b=strrep(line1a, 'GET /?'  ,'');
    line1c=strrep(line1b, 'HTTP/1.1','');
    
    if (strfind(line1c, 'UAS'))
        line1d = line1c ;
    else
        % UAS not clicked on...
        line1d = strrep(line1c, 'Age', 'UAS=homozygote&Age');
    end
    
    % will return line as cell array
    lineSaved = strsplit(line1d, '&');
    line = lineSaved ;
else
    %newer code
    line1b=strrep(line1a, 'GET /,'  ,'');
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

try
    alldata = csvread(fName, 1,0);
catch
%     %% try to read the file as compressed
[fid, msg] = fopen(fName, 'rt');
    %line1a = fgets(fid)
    %original code was 132; later was extended to 135
    A1 = fread(fid,[1,132],'uint8') ; %read this and throw it away as we've already read this
    
    %allocate memory for the data
    alldata = zeros (1025*5, 3) ;
    
    try
        for i = 0 : 4
            alldata ((i*1025)+1:(i*1025)+1025, 3) = fread(fid,[1,1025],'int32') ; %  block of ergs   
            alldata ((i*1025)+1:(i*1025)+1025, 1) = fread(fid,[1,1025],'int32') ; %  block of time_data
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

stimdata = alldata(1:1024,2);
[mm,ii]=max(stimdata) ;

iStart = 1;
iEnd = 1024;
xdata = linspace(0,250); % fft will go to 250 Hz if we have 2ms / sample

%% test if figure exists, if so close it
if ~isempty(findall(0,'Type','Figure'))
    close;
end
%% big screen picture...
if (do_fft)
    ss = get (0,'screensize') ;
    myPos = ss ;
    myPos(1) = 10 ;
    myPos(3) = ss(3) - 10 ;
    figure ('Name', strcat('Data from: ',fileName), 'Position', myPos, 'PaperSize', [80 40]);
end

%% do plotting
ymax = 600 ; %max(alldata(:,3)) ;
ymin = -1200 ; %min(alldata(:,3)) ;

rawdata=zeros(nContrasts,1024);
fft1 = zeros(nContrasts,200);
fft2 = zeros(nContrasts,200);

for i = 1:nContrasts
    
    rawdata(i,:)=alldata(iStart:iEnd,3) ;
    % contrasts(i,:) = alldata(iEnd+1,:) ;
    
    %now we've read the data, lets plot it
    if (do_fft)
        subplot(nContrasts +2, 4, (i*4)-3);
    else
        subplot(4, 2, i);
    end
    plot (timedata, rawdata(i,:), timedata, stimdata);
    axis([0 timedata(1024) ymin ymax]);
    
    yTxt = strcat(num2str(i), '//') ;
    ylabel(yTxt);
    
    if (i==1)
        line1d = strrep(line1c, '&',' ');
        line1e = strrep(line1d, '_',' ');
        text(-500,ymax*1.2,line1e);
    end
    %   keyboard;
    if (do_fft)
        fft1(i,:)=abs(fft(rawdata(i,1:200)))/1000;
        subplot(nContrasts +2, 4, (i*4)-2);
        bar (xdata(20:100), fft1(i,20:100));
        axis([0 175 0 15]);
        
        fft2(i,:)=abs(fft(rawdata(i,401:600)))/1000;
        subplot(nContrasts +2, 4, (i*4)-1);
        bar (xdata(20:100), fft2(i,20:100));
        axis([0 175 0 15]);
        
        subplot(nContrasts +2, 4, (i*4));
        spectrogram(rawdata(i,:),64, 32, [], 500,'yaxis');
        %caxis
    end
    
    iStart = iStart + 1025;
    iEnd = iEnd + 1025;
end;

%% average graphs
if (do_fft)
    subplot(nContrasts +2 ,4, (nContrasts*4) +1);
else
    subplot(4, 2, 7);
end ;
meandata = mean(rawdata);


plot (timedata, meandata,  timedata, stimdata);
axis([0 timedata(1024) ymin ymax]);
ylabel('mean');
%% plot mean ffts
if (do_fft)
    meanfft1= mean(fft1);
    meanfft2= mean(fft2);
    subplot(nContrasts +2 ,4, (nContrasts*4) +2);
    bar (xdata(20:100), meanfft1(20:100));
    axis([0 175 0 15]);
    
    subplot(nContrasts +2 ,4, (nContrasts*4) +3);
    bar (xdata(20:100), meanfft2(20:100));
    axis([0 175 0 15]);
    [maxfft1,maxfft1at] = max(meanfft1(20:100));
    [maxfft2,maxfft2at] = max(meanfft2(20:100));
    
    maxfft1at = xdata(maxfft1at + 19) ;
    maxfft2at = xdata(maxfft2at + 19) ;
end

%% fit line to decay... extract decay in stimulus
[max_val,max_pos] = max(meandata) ;
[min_val,min_pos] = min(meandata) ;

[stim_start_val, stim_start_pos] = max(stimdata);
[stim_end_val, stim_end_pos] = min(stimdata(stim_start_pos +1:end));
stim_end_pos= stim_end_pos+stim_start_pos + 1;

decaydata = meandata (stim_start_pos:stim_end_pos);
decaytimedata = timedata(stim_start_pos:stim_end_pos);
decaytimedata = decaytimedata - decaytimedata(1);
%%% now do fit
f = fit(decaytimedata(:),decaydata(:),'exp1');
[ab]=coeffvalues(f);
if (do_fft)
    subplot(nContrasts +2 ,4, (nContrasts*4) +4);
else
    subplot(4, 2, 8);
end

plot (f,decaytimedata, decaydata);
legend('off');

xTxt = 'scales are in ms, Hz';
xlabel(xTxt);


%% is it too noisy ?
myNoise = std(meandata(1:300));
% if (myNoise > 100)
%     success = false ;
%     set(gcf,'Color','red');
% end
%%
sExt = 'pdf' ; % getPictExt ();
printFilename = [pathstr, filesep, fileName, '_MyData', sExt];
print( '-dpdf',  printFilename );

% %% not sure this is the best discriminat
% if (myNoise > 100)
%     return
% end


%% get some data out
disp('mean ERG:');
lineSaved = [lineSaved, {['nRepeats =',num2str(nContrasts  )]}];
lineSaved = [lineSaved, {['max =',     num2str(max_val)]}];
lineSaved = [lineSaved, {['max_pos =', num2str(timedata(2)*max_pos)]}];
lineSaved = [lineSaved, {['min =',     num2str(min_val)]}];
lineSaved = [lineSaved, {['min_pos =', num2str(timedata(2)*min_pos)]}];

lineSaved = [lineSaved, {['timeconst of response =', num2str(ab(2))]}];

lineSaved = [lineSaved, {['off-transient =', num2str(min(meandata(680:720))-mean(meandata(650:680)))]}];
lineSaved = [lineSaved, {['recovery =', num2str(max(meandata(720:820))-mean(meandata(650:680)))]}];
lineSaved = [lineSaved, {['on-transient =', num2str(max(meandata(300:380))-mean(meandata(300:340)))]}];
lineSaved = [lineSaved, {['peak-peak =', num2str(max(meandata)-min(meandata))]}];
lineSaved = [lineSaved, {['noise =', num2str(myNoise)]}];

if (do_fft)
   % keyboard;
    lineSaved = [lineSaved, {['maxFFT_start =', num2str(maxfft1)]}];
    lineSaved = [lineSaved, {['maxFFT_start_freq =', num2str(maxfft1at)]}];
    lineSaved = [lineSaved, {['maxFFT_stim =', num2str(maxfft2)]}];
    lineSaved = [lineSaved, {['maxFFT_stim_freq =', num2str(maxfft2at)]}];
end

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



