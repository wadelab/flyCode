
close all;
clear all; 

global SVPfiles ;
SVPfiles = {};

dirName=uigetdir();
walk_a_directory_recursively(dirName, '*.SVP');

%% now we have a list of all the files with .SVP in that tree
for i=1:length(SVPfiles)
    SVPfiles{i} = deblank(SVPfiles{i});
end


%% read all the rest of them (well, the first 20)
iSuccesseses = 1;
maxFilesToRead = 40 ;
for i=1:min(length(SVPfiles),maxFilesToRead)
    disp(SVPfiles{i});
    [flydata, success] = read_arduino_file ( SVPfiles{i} , false );
    if (success)
        % - now parse the line
        %
        if (iSuccesseses == 1)
            %set up an array to fill up
            Collected_Data = repmat(flydata, maxFilesToRead) ;
        end
        Collected_Data(iSuccesseses) = flydata;
        iSuccesseses = iSuccesseses + 1;
    end
end;
Collected_Data(iSuccesseses:end) = [] ; % remove all the unsused columns

disp('Number of flies in this analysis');
nFlies = length(Collected_Data)
savefileName = [dirName, filesep, 'CollectedData.mat'];
save(savefileName);

%% now we can process the data

[r,c] = size(Collected_Data(1).sorted_CRF);
allCRFs = zeros(nFlies,r,c);

for i = 1 : nFlies
    allCRFs(i,:,:)= Collected_Data(i).sorted_CRF;
end
%% 

%%calculate and plot the average
meanCRF = squeeze(mean(allCRFs));


[pathstr, fileName, ext] = fileparts(dirName);

% definition of frequency names is also in anothr filr ...

%% Plot mean CRFs 
FreqNames = {'1F1', '1F2', '2F1', '2F2', '1F1+1F2', '2F2+2F2', 'F2-F1' };
nUnMasked=flydata(1).nUnMasked ;

figure('Name', strcat(' mean CRFs of: ',fileName));

nPlots = length(FreqNames);
for i = 1 : nPlots
    
    subplot ( mod(nPlots,4), floor(nPlots/2), i);
    plot (meanCRF([1:nUnMasked],2), meanCRF([1:nUnMasked],i+2), '-*', meanCRF([nUnMasked+1:end],2), meanCRF([nUnMasked+1:end],i+2), '-.O' );
    legend('UNmasked', 'Masked', 'Location', 'NorthWest') ;
    set(gca,'XScale','log');
    title(FreqNames{i});
        
end

printFilename = [dirName, filesep, fileName, '_mean_CRF', '.eps'];
print( printFilename );


disp (['done! ', dirName]); 





