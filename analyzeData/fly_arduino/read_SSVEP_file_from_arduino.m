
close all;
clear all; 

[f,p]=uigetfile('*.SVP');
fName=fullfile(p,f);
[pathstr, fileName, ext] = fileparts(fName) ;


%%read first file and save x values
[flydata, success] = read_arduino_file ( fName, false );




