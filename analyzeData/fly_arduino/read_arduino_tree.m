
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

%%read first file and save x values
CRF_start = read_arduino_file ( SVPfiles{1} );

%% read all the rest of them (well, the first 20)
for i=2:min(length(SVPfiles),20)
   disp(SVPfiles{i});
   CRF_tmp = read_arduino_file ( SVPfiles{i} );
   CRF_start.UNmaskedCRF(:,i+1) = CRF_tmp.UNmaskedCRF(:,2);
   CRF_start.MaskedCRF(:,i+1) = CRF_tmp.MaskedCRF(:,2);
end;
%% 

%%calculate and plot the average
CRF_output.UNmaskedCRF=CRF_start.UNmaskedCRF(:,2:end) ;
meanCRF.UNmaskedCRF = mean(CRF_output.UNmaskedCRF, 2) ;

CRF_output.MaskedCRF=CRF_start.MaskedCRF(:,2:end) ;
meanCRF.MaskedCRF = mean(CRF_output.MaskedCRF, 2) ;

[pathstr, fileName, ext] = fileparts(fileName);
figure('Name',strcat('mean CRF', pathstr));
plot (CRF_start.UNmaskedCRF(:,1), CRF_start.UNmaskedCRF(:,2), '-*', CRF_start.MaskedCRF(:,1), CRF_start.MaskedCRF(:,2), '-.O' );
legend('UNmasked', 'Masked', 'Location', 'NorthWest') ;
set(gca,'XScale','log');


printFilename = [dirName, filesep, 'mean_CRF', '.eps']
print( printFilename );

% figure('Name',strcat('boxplot CRF', dirName));
% boxplot(transpose(CRF_output),'labels', CRF_start(:,1));
% set(gca,'YLim', [0, 200]);

disp (['done! ', dirName]); 





