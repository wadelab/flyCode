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


%% now calculate a csv file name
[pathstr, name, ext] = fileparts([newpathToLoad,newfileToLoad]);
outfile = [pathstr, '/', name,'_35pc_4_Excel.xlsx'];



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
%% Now we have to write out the data in the format

contrastmax = length(analysisStruct.contRange);
genotypemax = length(analysisStruct.phenotypeName) ;
masklabels = {'unmasked 35','masked 35'}
% outcells{1,1} = 'unmasked 35';
% outcells{genotypemax + 3,1} = 'masked 35';

maskmax = 2 ;

%% build truth table (goor fly/bad fly)
freqFF = 1;
mask = 1;
for genotype = 1 : genotypemax
    flymax = analysisStruct.nFlies{genotype};
    for fly = 1 : flymax
        max_response= 0.0;
        for contrast = 1 : contrastmax
            %calculate the response
            response = abs(analysisStruct.allFlyDataCoh{1,genotype}(fly,freqFF,contrast,mask));
            if (response > max_response)
                max_response = response ;
            end ;
        end % contras
        goodfly(genotype, fly) = (max_response > 5 * abs(analysisStruct.allFlyDataCoh{1,genotype}(fly,freqFF,1,mask))) & (abs(analysisStruct.allFlyDataCoh{1,genotype}(fly,freqFF,5,mask)) > 1/1000);
        % good fly
        
    end %of this fly
    
end



%% now do the output

FreqLabels ={'1F1','1F2','2F1','2F2', '1F1+1F2','2F1+2F2'};
contrast = 5 ;
freqmax=length(FreqLabels);
for freqFF = 1: freqmax;
    
    for mask = 1 : maskmax
    for genotype = 1 : genotypemax

                %%convert the indexes to humean friendly forms...
        genotype_str = analysisStruct.phenotypeName{genotype} ;
        genotype_str = strrep (genotype_str,'all', '');
        genotype_str = strrep (genotype_str,'_1_', ' 01, ');
        genotype_str = strrep (genotype_str,'_7_', ' 07, ');
        genotype_str = strrep (genotype_str,'_14_', ' 14, ');
        genotype_str = strrep (genotype_str,'_21_', ' 21, ');
        genotype_str = strrep (genotype_str,'_', ' ');
        genotype_str = strrep (genotype_str,'D ', '');
        genotype_str = strrep (genotype_str,'LD', '0LD');
        genotype_str = strrep (genotype_str,'0uM Bottle', '');
        genotype_str = strrep (genotype_str,'001', '');
        genotype_str = strrep (genotype_str,'002', '');
        genotype_str = strrep (genotype_str,'003', '');
        genotype_str = strrep (genotype_str,'004', '');
        genotype_str = strrep (genotype_str,'005', '');
        genotype_str = strrep (genotype_str,'006', '');
        genotype_str = strrep (genotype_str,'  ', ' ');
        genotype_str = strtrim(genotype_str);
        
        outcells{genotype + 1, 1} = genotype_str ;
%         outcells{genotypemax + genotype + 3, 1} = genotype_str ;
        
        flymax = analysisStruct.nFlies{genotype};
        
%             if mask == 1
                offset = 1;
%             else
%                 offset = genotypemax + 3;
%             end
            
            for fly = 1 : flymax
                response = abs(analysisStruct.allFlyDataCoh{1,genotype}(fly,freqFF,contrast,mask));
                
                if goodfly(genotype, fly)
                    numcells{ genotype + offset, fly} = 1000 * (response) ;
                end
            end
        end
   
    
    
    % Generate XLSX file
    disp([' processing : ', FreqLabels{freqFF} ]);
    [status]=xlwrite(outfile, outcells,[FreqLabels{freqFF}, ' ', masklabels{mask}],'g8');
    [status]=xlwrite(outfile, numcells,[FreqLabels{freqFF}, ' ', masklabels{mask}],'i8');
         
    end
end
disp (['file written ', outfile]);
