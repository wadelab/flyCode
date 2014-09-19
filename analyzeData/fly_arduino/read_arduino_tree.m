
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
nFlies = length(line_tmp(1,:));

[pathstr, fileName, ext] = fileparts(dirName);

% this is also in anothr place ...
FreqNames = {'1F1', '1F2', '2F1', '2F2', '1F1+1F2', '2F2+2F2' };


%% Plot mean 12 Hz CRF 
figure('Name', strcat('1F1 Hz mean CRF of: ',fileName));
plot (meanCRF([1:nUnMasked],2), meanCRF([1:nUnMasked],3), '-*', meanCRF([nUnMasked+1:end],2), meanCRF([nUnMasked+1:end],3), '-.O' );
legend('UNmasked', 'Masked', 'Location', 'NorthWest') ;
set(gca,'XScale','log');

printFilename = [pathstr, '_mean_', FreqNames{1}, '_CRF', '.eps'];
print( printFilename );


%% Plot mean 24 Hz CRF 
figure('Name', strcat('2F1 Hz mean CRF of: ',fileName));
plot (meanCRF([1:nUnMasked],2), meanCRF([1:nUnMasked],5), '-*', meanCRF([nUnMasked+1:end],2), meanCRF([nUnMasked+1:end],5), '-.O' );
legend('UNmasked', 'Masked', 'Location', 'NorthWest') ;
set(gca,'XScale','log');

printFilename = [pathstr, filesep, fileName, '_mean_', FreqNames{3}, '_CRF', '.eps'];
print( printFilename );

disp (['done! ', dirName]); 





