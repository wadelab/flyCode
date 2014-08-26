% What is this?

%% This file takes an analysis*.mat file, which contains all the data and writes it out to a format for SPSS or Excel
% cjhe, 18 Aug 2014

clear all;
close all;



IGNORE_PHOTODIODE_FLAG=1; % Normally we don't want to waste time processing the photodiode phenotype since it's a) not physiologically interesting and b) statistically different from everything else


[fileToLoad,pathToLoad]=uigetfile('*Analysis*.mat','Load analysis file');
[pathstr, name, ext] = fileparts(fileToLoad);
b = [pathToLoad,name, '_analysed_',datestr(now,30)];


load(fullfile(pathToLoad,fileToLoad)); % This is the file you got from the directory analysis script. It will place a structure calles 'analysisStruct' in the workspace
% ** Obviously you replace the filename above with the one that you saved
% out from the selectLoadAnalyze... script' Or make the call above a
% uigetfile to browse .


%% now calculate a csv file name
[pathstr, name, ext] = fileparts([pathToLoad,fileToLoad]);
outfile = [pathstr, '/', name,'_MANOVA_forSPSS.csv'];
fileID = fopen(outfile, 'w+');
if fileID < 3
    error (['file not opened', outfile]);
end
%% Now we have to write out the data in the format
% Fly, F, contrast, mask, response, genotype 
% we put genotype last so it can be split in Excel
iPreviousFlies = 1;
contrastmax = nConts;
maskmax = 2 ;
freqmax = nFreqs;
genotypemax = length(analysisStruct.phenotypeName) ;

%fill up top row
for freq = 1 : freqmax 
    freq_str = plotParams.labelList{freq} ;
    outcells(iPreviousFlies, freq) = {freq_str} ;
end

outcells(iPreviousFlies, 7) = {'fly'};
outcells(iPreviousFlies, 8) = {'mask'};
outcells(iPreviousFlies, 9) = {'genotype '};

iPreviousFlies = iPreviousFlies + 1;

for genotype = 1 : genotypemax
    flymax = analysisStruct.nFlies{genotype};
    
    for fly = 1 : flymax
        for mask = 1 : maskmax
            for freq = 1 : freqmax
                outcells(iPreviousFlies, freq) = {' '}; %% make sure we always put an empty string in the box
                if ((( mask == 1 ) && ( freq == 2)) || (( mask == 1 ) && ( freq >= 4)) )
                    %% ignore the unmasked F and 2F
                    
                else
                    
                    %% in this version fill in the F1... table per fly, all along the same line
                    % find max response of this Contrast
                    max_response= 0.0;
                    for contrast = 1 : contrastmax
                        %calculate the response
                        response = abs(analysisStruct.allFlyDataCoh{1,genotype}(fly,freq,contrast,mask));
                        if (response > max_response)
                            max_response = response ;
                        end ;
                    end % contrast
                    %%calculate the max_response as a ratio of the masked F2
                    F2_response = abs(analysisStruct.allFlyDataCoh{1,genotype}(fly,2,1,2));
                    ratio_response = max_response / F2_response ;
                    
                    %%convert the indexes to humean friendly forms...
                    genotype_str = analysisStruct.phenotypeName{genotype} ;
                    if mask == 1
                        mask_str='unmasked';
                    else
                        mask_str='masked';
                    end
                    
                    
                    %%write the cell
                    outcells(iPreviousFlies, freq) = {num2str(max_response)}; %%%%% num2str(ratio_response); };
                end %% end of if
            end % freq
            
            outcells(iPreviousFlies, 7) = {num2str(fly)};
            outcells(iPreviousFlies, 8) = {mask_str};
            outcells(iPreviousFlies, 9) = {genotype_str};
            iPreviousFlies = iPreviousFlies + 1;
            
        end  %% of mask
        
    end % fly
end % genotype

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
