%%read_arduino_ERG

close all;
clear all;

ERGfiles = {};

addmetothepath ;


success = true ;
%
% [f,dirName]=uigetfile('*.ERG');
% filName=fullfile(dirName,f);

dirName=uigetdir();
ERGfiles = walk_a_directory_recursively(dirName, '*.ERG');
ERGfiles = [ERGfiles, walk_a_directory_recursively(dirName, '*.erg')];

%% now we have a list of all the files with .SVP in that tree
if (length(ERGfiles) ==0)
    disp(['Exiting becuase No ERG files were found in ',dirName]);
    return
end

for i=1:length(ERGfiles)
    ERGfiles{i} = deblank(ERGfiles{i});
end

Collected_ERG_Data = {} ;
%% read all the rest of them (well, the first 40)
iSuccesseses = 1;

maxFilesToRead = length(ERGfiles) + 3 ;
for i=1:min(length(ERGfiles),maxFilesToRead)
    disp(['Reading:', ERGfiles{i}]);
    [success, ERGData] = read_arduino_ERG_file ( ERGfiles{i}, false  );
    if (success)
        Collected_ERG_Data=[Collected_ERG_Data;ERGData];
        iSuccesseses = iSuccesseses + 1 ;
    end
end;

if (iSuccesseses == 1)
    disp(['Exiting becuase No **Readable** SVP files were found in ',dirName]);
    return
end


disp('Number of flies in this analysis');
sss = size(Collected_ERG_Data) ;
nFlies = sss(1)
savefileName = [dirName, filesep, 'CollectedData.mat'];
save(savefileName);



%% put it in Excel format
[row,col] = size(Collected_ERG_Data);
ERG_4_disp = { row+1, col };
for i = 1:col
    C = strsplit(Collected_ERG_Data{1,i}, '=');
    ERG_4_disp{1, i} = C{1};
end
for k = 1 : row
    for i = 1 : col
        if strfind(Collected_ERG_Data{k,i}, '=')
            C = strsplit(Collected_ERG_Data{k,i}, '=');
            ERG_4_disp{k+1, i} = C{2};
        end
    end
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
analysistime = datestr(now,'mmmm_dd_yyyy_HH_MM');
filename = [ dirName, '/summary_of_ERGs_', analysistime, '.xls'];
status=xlwrite(filename, ERG_4_disp, 'ERGs', 'A1');





%% now try and build a list for excle more sanely...
clear phenotypelistZ ;
clear ERG_Table ;
for k = 1 : row
    disp(k);
    sTmp = strjoin(Collected_ERG_Data(k,1:9));
    if k == 1
        phenotypelistZ = {sTmp} ;
    else
        phenotypelistZ = [phenotypelistZ, sTmp ];
    end
end

%% now we have aphenotype list, so put it in the new Excel sheet
[myphenotypes,iN,iIndex]=unique(phenotypelistZ);

Nphenotypes = length(myphenotypes);
for i = 1 : Nphenotypes
    sTmp = myphenotypes {i} ;
    sTmp = strrep(sTmp, 'org=fly col=blue F1=12 F2=15 stim=fERG','');
    sTmp = strrep(sTmp, 'sex=f col=blue F1=12 F2=15 stim=fERG','');
   ERG_Table {i,1} = sTmp; 
end

%% now we need the peak-peak values..
% have a default value
iPeakPeak = 17 ;
for k = 1 : col
   sTmp = Collected_ERG_Data{1, k}; 
   if strfind(sTmp, 'peak-peak')
       iPeakPeak = k ;
   end    
end
%% fill in the values, leaving space for a top of table calculation of teh average
ERG_index(1:Nphenotypes,1) = 6 ;

for k = 1 : row
    myValue = Collected_ERG_Data{k,iPeakPeak};
    myColumn = iIndex(k) ;
    ERG_index(myColumn) = ERG_index(myColumn) + 1;
    ERG_Table {iIndex(k), ERG_index(myColumn)} = strrep(myValue, 'peak-peak =','');
    
end

%% write out next sheet
status=xlwrite(filename, ERG_Table, 'ERG Peak-Peak', 'A1');

%%
disp(' ');
disp ([filename, ' written! ']);
disp(' ');

