
close all;
clear all;

global SVPfiles ;
SVPfiles = {};
sExt = getPictExt () ;

dirName=uigetdir();
walk_a_directory_recursively(dirName, '*.SVP');

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
maxFilesToRead = 40 ;
for i=1:min(length(SVPfiles),maxFilesToRead)
    disp(['Reading:', SVPfiles{i}]);
    [flydata, success] = read_arduino_file ( SVPfiles{i} , true );
    if (success)

        if (iSuccesseses == 1)
            %set up an array to fill up
            Collected_Data = repmat(flydata, maxFilesToRead) ;
        end
        
        Collected_Data(iSuccesseses) = flydata;
        phenotypeList{iSuccesseses} = strjoin(transpose(flydata.phenotypes(:)),'&');
        
        iSuccesseses = iSuccesseses + 1;
    end
end;

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

%% count how many flies in each phenotype
id (1) = ib (1);
for i = 2 : length(ib)
    id(i) = ib(i) - ib(i-1);
end

%% now we can process the data
% ia tells us the starting value of each phenotype
% ib tellsSo us the end of each phenotype
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
nFlies = zeros(nPhenotypes);

%%


for phen = 1 : nPhenotypes
    nFlies (phen) = ib(phen) - ia(phen) ;
    mean_phenotypeFFT(phen,:,:)=squeeze(mean(SortedFFTmatrix(ia(phen):ib(phen),:,:),1));
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
    
%% calculate max response
maxCRR = max(squeeze(abs(max (meanCRF, [], 2))));
%% plot mean and SE for each phenotype
for phen = 1 : nPhenotypes
    plot_mean_crf (SortedData(ia(phen)).phenotypes, squeeze(meanCRF(phen,:,:)),pathstr,[' phenotype ', num2str(phen)], false, squeeze(SE_CRF(phen,:,:)), maxCRR);
end

disp (['done! ', dirName]);
disp(' ');

%% write out the max CRF for each phenotype
disp ('Now writing mean max 1F1 and 2F1 with SE');
disp(' ');
for i = 1 : nPhenotypes
   myTxt = ['']; 
   for j=1 : length(SortedData(ia(i)).phenotypes)
      myTxt = [ myTxt, SortedData(ia(i)).phenotypes{j}, ' '];   
   end
    myTxt = [myTxt,' 1F1=',num2str(abs(meanCRF(i,5,3))),'=',num2str(abs(SE_CRF(i,5,3))),' 2F1=', num2str(abs(meanCRF(i,5,5))), '=', num2str(abs(SE_CRF(i,5,5))), ' nFlies=', num2str(nFlies(i))]; 
    disp (myTxt);
end



