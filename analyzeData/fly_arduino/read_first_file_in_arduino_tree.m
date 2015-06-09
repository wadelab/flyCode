
close all;
clear all; 
addmetothepath ;

global SVPfiles ;

SVPfiles = {};

dirName=uigetdir();
walk_a_directory_recursively(dirName, '*.SVP');

%% now we have a list of all the files with .SVP in that tree

%%read first file and save x values
[flydata, success] = read_arduino_file ( deblank(SVPfiles{1}), false );




