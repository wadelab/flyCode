% Script to 'reprogram' a data file from a fly experiment. Reads in the
% whole .mat file, extracts the bit listing the exptParams (the GUI
% settings)
% Then brings the GUI back up with those settings, allowing you to make
% changes
% Then saves out the data file again with the new settings.
% TODO - Loop over an entire directory
% Note: when you've finished, you need to move the backup files out.
% ARW 17.7.15
% This version even more weaponized: Now takes a directory name.
% Gets a list of all output files in that dir.
% Loads in the first one.
% Allows you to edit
% Then applies that edit to all other files.


dirToProcess=uigetdir(pwd);

% Get a list of all .mat files in there..
[d]=dir(fullfile(dirToProcess,'*.mat'));
% Load in the first file..
if (length(d)>0)
    
    loadedData=load(fullfile(dirToProcess,d(1).name));
    [exptData,canc]=fly_runParseInputGui(loadedData.exptParams); % This bit re-runs the gui you see when you first collect the data
    if (~canc)
        % Loop over all files in d
        for thisFile=1:length(d)
            fullName=fullfile(dirToProcess,d(thisFile).name); % Generate the full name of the current file
            fprintf('\nProcessing file %s',fullName);
            loadedData=load(fullName);
            
            
            
            nData=loadedData;
            % Save some of the things that are specific to this file (the dte and
            % time of the expt.)
            exptData.startTime=loadedData.exptParams.startTime;
            exptData.startTimeString=loadedData.exptParams.startTimeString;
            exptData.endTime=loadedData.exptParams.endTime;
            exptData.endTimeString=loadedData.exptParams.endTimeString;
            
            
            
            loadedData.exptParams=exptData; % Copy in the new expt params (with the preserved dates)
            
            % Make a backup
            [pn,fn,xn]=fileparts(fullName);
            
            cpName=[fn,'.bak'];
            save(fullfile(p,cpName),'-struct','nData');
            % Save over the original file
            save(fullName,'-struct','loadedData');
            fprintf('\nSaved %s',fullName);
        end % Next fly
        fprintf('\nProcessed %d files',thisFile);
       
    else
        disp('Cancelled');
    end
    
    
else % Didn't find any files in the selected directory with .mat extensions
    error('No mat files in this dir');
end

