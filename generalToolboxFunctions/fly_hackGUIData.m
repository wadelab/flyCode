% Script to 'reprogram' a data file from a fly experiment. Reads in the
% whole .mat file, extracts the bit listing the exptParams (the GUI
% settings)
% Then brings the GUI back up with those settings, allowing you to make
% changes
% Then saves out the data file again with the new settings.



[f,p]=uigetfile(pwd);
loadedData=load(fullfile(p,f));
[exptData]=fly_runParseInputGui(loadedData.exptParams);
nData=loadedData;
loadedData.exptParams=exptData;
% Make a backup
cpName=[f,'_.backup'];
save(fullfile(p,cpName),'-struct','nData');
% Save over the original file
save(fullfile(p,f),'-struct','loadedData');





