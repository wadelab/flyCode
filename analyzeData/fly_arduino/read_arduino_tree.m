function [] =read_arduino_tree(fInputDir, varargin)


%%
%handle arguments..

%%
close all;
%clear all;
clearvars -except fInputDir nargin
writeAllData = false;

SVPfiles = {};
badSVPFiles = {};
fileIDs = {};
addmetothepath ;
sExt = getPictExt () ;

if nargin < 1
    dirName=uigetdir();
else
    dirName = fInputDir
end
SVPfiles =  walk_a_directory_recursively(dirName, '*.SVP');
SVPfiles = [SVPfiles; walk_a_directory_recursively(dirName, '*.svp')];
SVPfiles = [SVPfiles; walk_a_directory_recursively(dirName, '*.SVP.txt')];


%% now we have a list of all the files with .SVP in that tree
if (length(SVPfiles) ==0)
   disp(['Exiting becuase No SVP files were found in ',dirName]);
   return 
end

for i=1:length(SVPfiles)
    SVPfiles{i} = deblank(SVPfiles{i});
end


%% read all the rest of them (well, the first 40)
iSuccesseses = 1;
maxFilesToRead = length(SVPfiles) + 3 ;
for i=1:min(length(SVPfiles),maxFilesToRead)
    disp(['Reading:', SVPfiles{i}]);
    [flydata, success] = read_arduino_file ( SVPfiles{i} , true );
    if (success)
        % test if file already analysed..
        % if not already analysed
        if any(strcmp(fileIDs,flydata.fileName))
            disp(['Duplicate file found' , flydata.fileName]);
        else
            fileIDs = [fileIDs;flydata.fileName];
            
            if (iSuccesseses == 1)
                %set up an array to fill up
                Collected_Data = repmat(flydata, maxFilesToRead) ;
            end
            
            Collected_Data(iSuccesseses) = flydata;
            phenotypeList{iSuccesseses} = strjoin(transpose(flydata.phenotypes(:)),'&');
            
            iSuccesseses = iSuccesseses + 1;
        end
    else
        badSVPFiles = [badSVPFiles;SVPfiles{i}];
    end
end

%%
if (iSuccesseses == 1)
   disp(['Exiting becuase No **Readable** SVP files were found in ',dirName]);
   return 
end

Collected_Data(iSuccesseses:end) = [] ; % remove all the unsused columns

disp('Number of flies in this analysis');
nFlies = length(Collected_Data)
savefileName = [dirName, filesep, 'CollectedData.mat'];
save(savefileName);

%% Sort the data and work out how many of each phenotype we have 
[SortedPhenotypes,z]=sort(phenotypeList) ;
SortedData=Collected_Data(z);
[C, ia, ic] = unique(SortedPhenotypes, 'stable');

nPhenotypes = length(ia)
ib = ia(2:end) - 1;
ib(nPhenotypes) = length(ic) ;


%% now we can process the data
% ia tells us the starting value of each phenotype
% ib tells us the end of each phenotype
% length(ia) tells us how many phenotypes we have 

% copy data into matrix otherwise we can't get the mean...
[r,c] = size(SortedData(1).meanFFT);
SortedFFTmatrix = zeros(nFlies,r,c);

for i = 1 : nFlies
    SortedFFTmatrix(i,:,:) = SortedData(i).meanFFT ;
end


%% calculate  mean and SE for each phenotype (SE on per fly basis)
[pathstr, fileName, ext] = fileparts(dirName);
mean_phenotypeFFT = zeros(nPhenotypes,r,c);
meanCRF = zeros(nPhenotypes,length(SortedData(1).meanContrasts), 2+length(GetFreqNames()));

SD_phenotypeFFT = zeros(nPhenotypes,r,c);
SE_CRF = zeros(nPhenotypes,length(SortedData(1).meanContrasts), 2+length(GetFreqNames()));
nFlies = zeros(nPhenotypes,1);




%% Calculate average and SD


for phen = 1 : nPhenotypes
    nFlies (phen) = 1 + ib(phen) - ia(phen) ;
    mean_phenotypeFFT(phen,:,:)=squeeze(mean(SortedFFTmatrix(ia(phen):ib(phen),:,:),1));
    % don't try to calculate a SD of 1 fly
    if ia(phen) ~= ib(phen)
    SD_phenotypeFFT(phen,:,:)=squeeze(std(SortedFFTmatrix(ia(phen):ib(phen),:,:),1)); 
    end 
    
    phenFFT =squeeze(mean_phenotypeFFT(phen,:,:)); % complex
    phenSD  =squeeze( SD_phenotypeFFT (phen,:,:)); % scalar
    
    meanCRF(phen,:,:) = Calculate_CRF(SortedData(phen).meanContrasts, phenFFT);
    tmpCRF = Calculate_CRF(SortedData(phen).meanContrasts, phenSD);
    
    SE_CRF (phen,:,:) = tmpCRF / sqrt(nFlies(phen)) ;
    % plot_mean_crf (squeeze(meanCRF(phen,:,:)),pathstr,[' phenotype ', num2str(phen)], false, squeeze(SE_CRF(phen,:,:)));
end


%% HB and GDS:  Initialise matrices to save out individual fly amplitudes
%% and phases for 1F1 and 2F1
CRF_Max = max(nPhenotypes, max(nFlies));
% FreqsToExtract = [ F1, F2, 2*F1, 2*F2, F1+F2, 2*(F1+F2), F2-F1 ];
FreqsToExtract = [48,60,96,120,108,216,12] ; % 4 times the real value...
phenotypeAmps=NaN(CRF_Max,nPhenotypes,length(FreqsToExtract));
phenotypePh=NaN(CRF_Max,nPhenotypes, length(FreqsToExtract));


%% HB and GDS:  Calculate and save individual fly amplitudes
%% and phases for  the 100% contrast condition
% Column 5 = 100% contrast column 8 is 30:30;  
ContrastToExtract = [5,5,5,5,8,8,8] ; % 4 for Rory and Sam

for phen = 1 : nPhenotypes
    nFlies (phen) = 1 + ib(phen) - ia(phen) ;
    for j = 1 : length(FreqsToExtract)
    phenotypeAmps(1:nFlies(phen,1),phen,j)= squeeze(abs(SortedFFTmatrix(ia(phen):ib(phen),ContrastToExtract(j),FreqsToExtract(j))));
    phenotypePh(1:nFlies(phen,1),phen,j)= squeeze(angle(SortedFFTmatrix(ia(phen):ib(phen),ContrastToExtract(j),FreqsToExtract(j))));
    end
end
    
%% calculate max response
maxCRR = squeeze(abs(max (meanCRF, [], 2)));
if (nPhenotypes > 1)
    maxCRR = max(maxCRR);
end

%% plot mean and SE for each phenotype
for phen = 1 : nPhenotypes
    myTxt = ['N=',num2str(nFlies (phen)),' '];
    
    phenName{phen} = strjoin(SortedData(ia(phen)).phenotypes);
    tmpTxt = SortedData(ia(phen)).phenotypes ;
    for q = 1 : length(tmpTxt)
        qPos = strfind(tmpTxt{q},'=');
        tmpTxt{q} = tmpTxt{q}(qPos+1:end);
    end
    %if we are here, its bound to be an SSVEP...
    phenName{phen} = strrep(strjoin(tmpTxt),'SSVEP','');
    
    if writeAllData
        plot_mean_crf ({myTxt,phenName{phen}}, squeeze(meanCRF(phen,:,:)), dirName, [' phenotype ', num2str(phen)], true, squeeze(SE_CRF(phen,:,:)), maxCRR);
    end
end

%% write out the max CRF for each phenotype
disp ('Now writing mean max 1F1 and 2F1 with SE');
disp(' ');
for i = 1 : nPhenotypes
   myTxt = ['']; 
   for j=1 : length(SortedData(ia(i)).phenotypes)
      myTxt = [ myTxt, SortedData(ia(i)).phenotypes{j}, ' '];   
   end
    myTxt = [myTxt,' 1F1=',num2str(abs(meanCRF(i,5,3))),'=',num2str(abs(SE_CRF(i,5,3))), ...
        ' 2F1=', num2str(abs(meanCRF(i,5,5))), '=', num2str(abs(SE_CRF(i,5,5))), ' nFlies=', num2str(nFlies(i))]; 
    disp (myTxt);
end
%% add extra path..

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
dt = datestr(now,'mmm_dd_HH_MM');
filename = [ dirName, '/SSVEP_', dt, '_summary.xls']
status=xlwrite(filename, phenName, '1F1 unmasked', 'A1');
status=xlwrite(filename, phenName, '2F1 unmasked', 'A1');
status=xlwrite(filename, phenName, '1F1+1F2 masked', 'A1');
status=xlwrite(filename, phenName, '1F2-1F1 masked', 'A1');

status=xlwrite(filename, phenotypeAmps(:,:,1), '1F1 unmasked', 'A2');
status=xlwrite(filename, phenotypeAmps(:,:,3), '2F1 unmasked', 'A2');
status=xlwrite(filename, phenotypeAmps(:,:,5), '1F1+1F2 masked', 'A2');
status=xlwrite(filename, phenotypeAmps(:,:,7), '1F2-1F1 masked', 'A2');

status=xlwrite(filename, phenName, '1F1_phase', 'A1');
status=xlwrite(filename, phenName, '2F1_phase', 'A1');
status=xlwrite(filename, phenotypePh(:,:,1), '1F1_phase', 'A2');
status=xlwrite(filename, phenotypePh(:,:,3), '2F1_phase', 'A2');

%% now add a page with the data tabulated vertically 
outcells={'genotype','1F1 unmasked','2F1 unmasked','1F1+1F2 masked', '1F2-1F1 masked', '1F1_phase','2F1_phase', 'filename'};
iPreviousFlies = 1;
k = 1 ;
sZ = size(phenotypeAmps(:,:,1));
myNAN = isnan(phenotypeAmps(:,:,1));
for j = 1: sZ(2)
    for i = 1 : sZ(1)
        if (~myNAN(i,j))
            iPreviousFlies = iPreviousFlies + 1;
            outcells{iPreviousFlies,1} = phenName{j};
            outcells{iPreviousFlies,2} = phenotypeAmps(i,j,1); %1F1 unmasked
            outcells{iPreviousFlies,3} = phenotypeAmps(i,j,3); %2F1 unmasked
            outcells{iPreviousFlies,4} = phenotypeAmps(i,j,5); %1F1+1F2 masked
            outcells{iPreviousFlies,5} = phenotypeAmps(i,j,7); %1F1-1F2 masked
            outcells{iPreviousFlies,6} = phenotypePh(i,j,1);
            outcells{iPreviousFlies,7} = phenotypePh(i,j,3);
            outcells{iPreviousFlies,8} = strrep(SortedData(k).fileName,'filename=','') ;
            k = k + 1 ;
        end
    end
end

status=xlwrite(filename, outcells, 'SPSS', 'A1');
%% write meanCRF here...
sTxt=[{'Mask','Contrast'},GetFreqNames()];

if writeAllData
    for phen = 1:nPhenotypes
        % phenotype..
        % mask, contrast, 1F1..
        % CRF
        sSheet = ['CRF of phen ', num2str(phen)] ;
        status=xlwrite(filename, [{'CRF for :'}, phenName{phen}], sSheet, 'A1');
        status=xlwrite(filename, sTxt, sSheet,'A2');
        status=xlwrite(filename, abs(squeeze(meanCRF(phen,:,:))),sSheet,'A3');
        
        if ia(phen) ~= ib(phen)
            %dont bother writing zeros..
            status=xlwrite(filename, {'SE'}, sSheet,'A14');
            status=xlwrite(filename, abs(squeeze(meanCRF(phen,:,1:2))), sSheet,'A15');
            status=xlwrite(filename, abs(squeeze(SE_CRF(phen,:,3:end))),sSheet,'C15');
        end
        
    end
end 
%%

savefileName = [dirName, filesep, 'CollectedArduinoData.mat'];
save(savefileName);

%% add list of files not read
if length(badSVPFiles)
   status=xlwrite(filename, badSVPFiles, 'Unread SSVEP Files', 'A1');
end

%% 
disp(' ');
disp ([dirName, ' done! ']);
disp(' ');

end
