
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


%% calculate and plot mean for each phenotype
[pathstr, fileName, ext] = fileparts(dirName);
mean_phenotypeFFT = zeros(nPhenotypes,r,c);
meanCRF = zeros(nPhenotypes,length(SortedData(1).meanContrasts), 2+length(GetFreqNames()));

for phen = 1 : nPhenotypes
    mean_phenotypeFFT(phen,:,:)=squeeze(mean(SortedFFTmatrix(ia(phen):ib(phen),:,:),1));    
    phenFFT =squeeze(mean_phenotypeFFT(phen,:,:));
    meanCRF(phen,:,:) = Calculate_CRF(SortedData(phen).meanContrasts, phenFFT, pathstr, fileName, false);
end
    

disp (['done! ', dirName]);

%% write out the max CRF for each phenotype
disp ('Now writing mean max 1F1 and 2F1');
disp(' ');
for i = 1 : nPhenotypes
   myTxt = ['']; 
   for j=1 : length(SortedData(i).phenotypes)
      myTxt = [ myTxt, SortedData(i).phenotypes{j}, ' '];   
   end
    myTxt = [myTxt,' 1F1=',num2str(abs(meanCRF(i,5,3))),' 2F1=', num2str(abs(meanCRF(i,5,5)))]; 
    myTxt = [myTxt, ' ', SortedData(i).fileName, ' '];
    disp (myTxt);
end



