
close all;
clear all;

global SVPfiles ;
SVPfiles = {};

dirName=uigetdir();
walk_a_directory_recursively(dirName, '*.SVP');

%% now we have a list of all the files with .SVP in that tree

%%read first file and save x values
CRF_start = read_arduino_file ( deblank(SVPfiles{1}) );

%% read all the rest of them
for i=2:length(SVPfiles)
   CRF_tmp = read_arduino_file ( deblank(SVPfiles{i}) );
   CRF_start(:,i+2) = CRF_tmp(:,3)
end;

%%calculate and plot the average
CRF_output=CRF_start(:,3:end) ;
meanCRF = mean(CRF_output, 2) ;

figure('Name',strcat('mean CRF', dirName));
plot (CRF_start(:,1), meanCRF, '*');

disp (['done!', dirName]);





