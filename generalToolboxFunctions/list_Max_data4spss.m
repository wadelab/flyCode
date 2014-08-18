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
outfile = [pathstr, '/', name,'_MAX_forSPSS.csv'];
fileID = fopen(outfile, 'w+');
if fileID < 3
    error (['file not opened', outfile]);
end
%% Now we have to write out the data in the format
% Fly, F, contrast, mask, response, genotype 
% we put genotype last so it can be split in Excel

contrastmax = nConts;
maskmax = 2 ;
freqmax = nFreqs;
genotypemax = length(analysisStruct.phenotypeName) ;

fprintf (fileID,'fly, mask, freq, max response, genotype \n');
for genotype = 1 : genotypemax
    flymax = analysisStruct.nFlies{genotype};
    for freq = 1 : freqmax
        for mask = 1 : maskmax
            if ((( mask == 1 ) && ( freq == 2)) || (( mask == 1 ) && ( freq >= 4)) ) 
                %% ignore the unmasked F and 2F
            else
            
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
                    if mask == 1
                        mask_str='unmasked';
                    else
                        mask_str='masked';
                    end
                    
                    freq_str= plotParams.labelList{freq} ;
                    end % contrast
                    %%write the line
                    fprintf (fileID, '%d,  %s, %s,%0.3e, %s \n', fly, mask_str, freq_str,  max_response, genotype_str);
                    
                end %  fly
            end  %% if
            end % freq
        end % mask
    
end % genotype
disp (['file written', outfile]);