
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
%% 



%% read all the rest of them (well, the first 20)
for i=1:min(length(SVPfiles),20)
    disp(SVPfiles{i});
    [CRF_tmp, line_tmp, success] = read_arduino_file ( SVPfiles{i} );
    if (success)
        % - now parse the line
        %
        Collected_CRF (i,:,:) = CRF_tmp ;
        Collected_line(i,:) = line_tmp ;
    end
end;
%% 

%%calculate and plot the average
meanCRF = squeeze(mean(Collected_CRF));
nUnMasked = sum(meanCRF(:,1)==0) ;
disp('Number of flies in this analysis');
nFlies = length(Collected_line)

[pathstr, fileName, ext] = fileparts(dirName);

% definition of frequency names is also in anothr filr ...

%% Plot mean 12 Hz CRF 
FreqNames = {'1F1', '1F2', '2F1', '2F2', '1F1+1F2', '2F2+2F2' };

figure('Name', strcat(' mean CRF of: ',fileName));

nPlots = length(FreqNames);
for i = 1 : nPlots
    
    subplot ( (nPlots/3), nPlots/2, i);
    plot (meanCRF([1:nUnMasked],2), meanCRF([1:nUnMasked],i+2), '-*', meanCRF([nUnMasked+1:end],2), meanCRF([nUnMasked+1:end],i+2), '-.O' );
    legend('UNmasked', 'Masked', 'Location', 'NorthWest') ;
    title(FreqNames{i});
   % set(gca,'XScale','log');
     
end

printFilename = [dirName, '_mean_CRF', '.eps'];
print( printFilename );


disp (['done! ', dirName]); 





