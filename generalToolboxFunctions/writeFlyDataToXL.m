function [status]=writeFlyDataToXL(filename,xlsData,semXlsData, xlParams)
% status=writeFlyDataToXL(filename,dataStruct)
% Uses xlwrite to write the main data structre from the fly analysis to XL
% Requires the XLWRITE toolbox from mathworks central
% This, in turn, uses a set of Java routines to do an excel export.
%
% This routine only writes out the magnitude data (in fact it should be
% renamed toreflect this). It writes out both the abs data and the sem of
% those same datapoints
% Different sheets hold different frequencies. All phenotypes are coded
% within a single sheet.


%% Initialisation of POI Libs
% Add Java POI Libs to matlab javapath
%%%%%%a='/data_biology/SSERG/toolbox/git/flyCode/generalToolboxFunctions/xlwrite/';
a=[fileparts(which ('writeFlyDataToXL.m')),filesep,'xlwrite/']

available=exist('xlwrite');
if (available ~=2)
    disp('You should add xlwrite to your path (it''s in the toolbox directory');
    
    addpath(a);
end

javaaddpath(fullfile(a,'poi_library/poi-3.8-20120326.jar'));
javaaddpath(fullfile(a,'poi_library/poi-ooxml-3.8-20120326.jar'));
javaaddpath(fullfile(a,'poi_library/poi-ooxml-schemas-3.8-20120326.jar'));
javaaddpath(fullfile(a,'poi_library/xmlbeans-2.3.0.jar'));
javaaddpath(fullfile(a,'poi_library/dom4j-1.6.1.jar'));
javaaddpath(fullfile(a,'poi_library/stax-api-1.0.1.jar'));

%% Data Generation for XLSX
% Define an xls name

for sheetIndex=1:length(xlParams.labelList)
    sheetName=xlParams.labelList{sheetIndex};
    absData=[]; semData=[]; phenotypeCode=[];
    for thisPhenotype=1:length(xlParams.phenotypeList)
        allData=xlsData{thisPhenotype}; 
        allsemData=semXlsData{thisPhenotype};
        cData=abs(squeeze(allData(sheetIndex,:,:)));
        sData=abs(squeeze(allsemData(sheetIndex,:,:)));
        absData=[cat(1,absData,cData)];
        size(sData)
        
        semData=[cat(1,semData,sData)];
        phenotypeCode=cat(1,phenotypeCode,ones(size(cData,1),1)*thisPhenotype);
        
    end
     size(absData)
     size(semData)
     size(phenotypeCode)
     outputData=cat(2,phenotypeCode,absData,semData);
     
%% Generate XLSX file
sheetName=xlParams.labelList{sheetIndex};
disp(sheetName)
[status]=xlwrite(filename, {'Phenotype index','Unmasked abs','Masked abs','Unmasked SEM','Masked SEM'},sheetName,'A1')
[status]=xlwrite(filename, outputData,sheetName,'A2')
sheetIndex

end


