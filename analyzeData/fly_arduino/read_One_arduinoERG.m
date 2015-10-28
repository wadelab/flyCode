%%read_arduino_ERG

close all;
clear all;

addmetothepath ;


success = true ;

[f,dirName]=uigetfile('*.ERG');
filName=fullfile(dirName,f);

%% save the data
[success,ERG_data]=read_arduino_ERG_file (filName);

%% test for valid file..
if (success)
    %% reformat it for Excel
    lMax = length(ERG_data);
    ERG_4_disp = { 2, lMax };
    for i = 1:lMax
        C = strsplit(ERG_data{i}, '=');
        ERG_4_disp{1, i} = C{1};
    end
    
    for i = 1:lMax
        C = strsplit(ERG_data{i}, '=');
        ERG_4_disp{2, i} = C{2};
    end
    
    %% Initialisation of POI Libs
    % Add Java POI Libs to matlab javapath
    %%%%%%a='/data_biology/SSERG/toolbox/git/flyCode/generalToolboxFunctions/xlwrite/';
    POIPATH=[fileparts(which ('writeFlyDataToXL.m')),filesep,'xlwrite/']
    
    javaaddpath(fullfile(POIPATH,'poi_library/poi-3.8-20120326.jar'));
    javaaddpath(fullfile(POIPATH,'poi_library/poi-ooxml-3.8-20120326.jar'));
    javaaddpath(fullfile(POIPATH,'poi_library/poi-ooxml-schemas-3.8-20120326.jar'));
    javaaddpath(fullfile(POIPATH,'poi_library/xmlbeans-2.3.0.jar'));
    javaaddpath(fullfile(POIPATH,'poi_library/dom4j-1.6.1.jar'));
    javaaddpath(fullfile(POIPATH,'poi_library/stax-api-1.0.1.jar'));
    
    
    %%  [status, message]=xlwrite(filename,A,sheet, range)
    C=strsplit (f,'.');
    filename = [ dirName, '/', C{1}, '.xls']
    status=xlwrite(filename, ERG_4_disp, 'ERGs', 'A1');
    
    
    
    %%
    disp(' ');
    disp ([dirName, ' done! ']);
    disp(' ');
    
else
    
    disp(' ');
    disp ([filName, 'failed ... exiting! ']);
    disp(' ');
end