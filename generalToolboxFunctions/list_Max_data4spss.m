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
outfile = [pathstr, '/', name,'_MAX_forSPSS.csv'];
fileID = fopen(outfile, 'w+');
if fileID < 3
    error (['file not opened', outfile]);
end
%% Now we have to write out the data in the format
% Fly, F, contrast, mask, response, genotype
% we put genotype last so it can be split in Excel%
iPreviousFlies = 1;
contrastmax = length(analysisStruct.contRange);
maskmax = 2 ;

FreqLabels ={'1F1','1F2','2F1','2F2', '1F1+1F2','2F1+2F2'};
freqmax=length(FreqLabels);

genotypemax = length(analysisStruct.phenotypeName) ;

if (isfield(analysisStruct,'startingTime'))
    outcells(iPreviousFlies,:) = {'genotype';   'max response'; 'max/masked F2[1]'; 'fly'; 'mask'; 'freq';'time date'};
else
    outcells(iPreviousFlies,:) = {'genotype';   'max response'; 'max/masked F2[1]'; 'fly'; 'mask'; 'freq'};
end
iPreviousFlies = iPreviousFlies + 1;

for freq = 1 : freqmax
    for mask = 1 : maskmax
        if ((( mask == 1 ) && ( freq == 2)) || (( mask == 1 ) && ( freq >= 4)) )
            %% ignore the unmasked F and 2F
        else
            for genotype = 1 : genotypemax
                flymax = analysisStruct.nFlies{genotype};
                
                
                
                for fly = 1 : flymax
                    
                    max_response= 0.0;
                    for contrast = 1 : contrastmax
                        %calculate the response
                        response = abs(analysisStruct.allFlyDataCoh{1,genotype}(fly,freq,contrast,mask));
                        if (response > max_response)
                            max_response = response ;
                        end ;
                        
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
                        if mask == 1
                            mask_str='unmasked';
                        else
                            mask_str='masked';
                        end
                        
                        freq_str= FreqLabels{freq} ; %%plotParams.labelList{freq} ;
                    end % contrast
                    
                    %%calculate the max_response as a ratio of the masked F2
                    F2_response = abs(analysisStruct.allFlyDataCoh{1,genotype}(fly,2,1,2));
                    ratio_response = max_response / F2_response ;
                    
                    %%write the line
                    if (isfield(analysisStruct,'startingTime'))
                    outcells(iPreviousFlies, :) = {genotype_str;  num2str(max_response); num2str(ratio_response); ...
                        num2str(fly); mask_str; freq_str ; analysisStruct.startingTime{genotype,fly}};
                    else
                       outcells(iPreviousFlies, :) = {genotype_str;  num2str(max_response); num2str(ratio_response); ...
                        num2str(fly); mask_str; freq_str };  
                    end
                    iPreviousFlies = iPreviousFlies + 1;
                    
                end
            end  %% if
        end % genotype
    end % mask
    
end %  freq

%% well csvwrite doesn't like my cell matrix, so do it outselves
%outM = celltomat(outcells);
%csvwrite(outfile, outM);

cSize = size(outcells);
for i =1:cSize(1)
    for j = 1: cSize(2)
        fprintf (fileID, outcells{i,j});
        fprintf (fileID, ', ');
    end
    fprintf (fileID,'\n');
end


disp (['file written ', outfile]);
