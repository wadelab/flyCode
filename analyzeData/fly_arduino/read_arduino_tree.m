
close all;
clear all; 

global SVPfiles ;
SVPfiles = {};

dirName=uigetdir();
walk_a_directory_recursively(dirName, '*.SWP');

%% now we have a list of all the files with .SVP in that tree

%%read first file and save x values
[U_CRF_start M_CRF_start]  = read_arduino_file ( deblank(SVPfiles{1}) );

%% read all the rest of them (well, the first 20)
for i=2:min(length(SVPfiles),20)
    disp(SVPfiles{i});
   CRF_tmp = read_arduino_file ( deblank(SVPfiles{i}) );
   CRF_start(:,i+2) = CRF_tmp(:,3)
end;
%% 

%%calculate and plot the average
CRF_output=CRF_start(:,3:end) ;
meanCRF = mean(CRF_output, 2) ;

figure('Name',strcat('mean CRF', dirName));
plot (CRF_start(:,1), meanCRF, '*');

figure('Name',strcat('boxplot CRF', dirName));
boxplot(transpose(CRF_output),'labels', CRF_start(:,1));
set(gca,'YLim', [0, 200]);

disp (['done!', dirName]); 





