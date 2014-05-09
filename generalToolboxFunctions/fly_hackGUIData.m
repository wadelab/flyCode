% Script to 'reprogram' a data file from a fly experiment. Reads in the
% whole .mat file, extracts the bit listing the exptParams (the GUI
% settings)
% Then brings the GUI back up with those settings, allowing you to make
% changes
% Then saves out the data file again with the new settings.
% TODO - Loop over an entire directory
% Note: when you've finished, you need to move the backup files out.



[f,p]=uigetfile(pwd);
loadedData=load(fullfile(p,f));
[exptData,canc]=fly_runParseInputGui(loadedData.exptParams);
if (~canc)
nData=loadedData;
loadedData.exptParams=exptData;
% Make a backup
[pn,fn,xn]=fileparts(f);

cpName=[fn,'.bak'];
save(fullfile(p,cpName),'-struct','nData');
% Save over the original file
save(fullfile(p,f),'-struct','loadedData');
fprintf('\nSaved %s',fullfile(p,f));

else
    disp('Cancelled');
end




