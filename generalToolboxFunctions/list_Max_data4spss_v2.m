% What is this?

%% This file takes an analysis*.mat file, which contains all the data and writes it out to a format for SPSS or Excel
% cjhe, 18 Aug 2014

clear all;
close all;



IGNORE_PHOTODIODE_FLAG=1; % Normally we don't want to waste time processing the photodiode phenotype since it's a) not physiologically interesting and b) statistically different from everything else


[newfileToLoad,newpathToLoad]=uigetfile('*Analysis*.mat','Load analysis file');
[pathstr, name, ext] = fileparts(newfileToLoad);
b = [newpathToLoad,name, '_analysed_',datestr(now,30)];


load(fullfile(newpathToLoad,newfileToLoad)); % This is the file you got from the directory analysis script. It will place a structure calles 'analysisStruct' in the workspace
% ** Obviously you replace the filename above with the one that you saved
% out from the selectLoadAnalyze... script' Or make the call above a
% uigetfile to browse .


%% now calculate a xls file name
[pathstr, name, ext] = fileparts([newpathToLoad,newfileToLoad]);
outfile = [pathstr, '/', name,'.xls'];
outfile = strrep (outfile,'_AnalysisData_noNorm', '');

% fileID = fopen(outfile, 'w+');
% if fileID < 3
%     error (['file not opened', outfile]);
% end
%% Now we have to write out the data in the format
% Fly, F, contrast, mask, response, genotype
% we put genotype last so it can be split in Excel%

contrastmax = length(analysisStruct.contRange);
maskmax = 2 ;

FreqLabels ={'1F1','1F2','2F1','2F2', '1F1+1F2','2F1+2F2'};
freqmax=length(FreqLabels);
maskLabel = {'_masked','_unmasked'};
genotypemax = length(analysisStruct.phenotypeName) ;

%% write the heading line
outcells{1,1} = cellstr('genotype');

for ff = 1 : freqmax
        for mask = 1 : maskmax
        outcells{1,(ff * 2) + mask - 1} = cellstr([FreqLabels{ff},maskLabel{mask}]);
        
        end
end
        
%%



iPreviousFlies = 1; 


for genotype = 1 : genotypemax
    flymax = analysisStruct.nFlies{genotype};
    
    %%convert the indexes to humean friendly forms...
    genotype_str = analysisStruct.phenotypeName{genotype} ;
    genotype_str = strrep (genotype_str,'all', '');
    genotype_str = strrep (genotype_str,'_1_', ' 01, ');
    genotype_str = strrep (genotype_str,'_7_', ' 07, ');
    genotype_str = strrep (genotype_str,'_14_', ' 14, ');
    genotype_str = strrep (genotype_str,'_21_', ' 21, ');
    genotype_str = strrep (genotype_str,'_', ' ');
    genotype_str = strrep (genotype_str,'D ', '');
    genotype_str = strrep (genotype_str,'0uM Bottle', '');
    
    for fly = 1 : flymax
        iPreviousFlies = iPreviousFlies + 1;
        outcells{iPreviousFlies,1} = cellstr(genotype_str) ;
        
        for freq = 1 : freqmax
            for mask = 1 : maskmax
                max_response= 0.0;
                for contrast = 1 : contrastmax
                    %calculate the response
                    response = abs(analysisStruct.allFlyDataCoh{1,genotype}(fly,freq,contrast,mask));
                    if (response > max_response)
                        max_response = response ;
                    end ;
                    
                end % contrast
                
                outcells{iPreviousFlies, (freq * 2) + mask - 1} = { num2str(max_response) };
                
                
                
            end
        end
    end
end

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
% fileID = fopen(outfile, 'w+');
% if fileID < 3
%     error (['file not opened', outfile]);
% end


%% well csvwrite doesn't like my cell matrix, so do it outselves
%outM = celltomat(outcells);
%csvwrite(outfile, outM);

% cSize = size(outcells);
% for i =1:cSize(1)
%     for j = 1: cSize(2)
%         a = outcells{i,j} ;
%         fprintf (fileID, '%s,', a{:});
%     end
%     fprintf (fileID,'\n');
% end

[status]=xlwrite(outfile, outcells,'SPSS','A1');

disp (['file written ', outfile]);
