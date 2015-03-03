
close all;
clear all;

global SVPfiles ;
SVPfiles = {};
sExt = getPictExt () ;

dirName=uigetdir();
walk_a_directory_recursively(dirName, '*.SVP');

%%
iBlock = 5 ;
choice = questdlg('Please choose which repeat to select:','Analsyse SSVEP repeat...','first','last','first') ;
if (strcmp (choice, 'first'))
    
        iBlock = 1;
        
end


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
    disp(SVPfiles{i});
    [flydata, success] = read_arduino_block (iBlock, SVPfiles{i} , true );
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
% ib tells us the end of each phenotype
% length(ia) tells us how many phenotypes we have 

% copy data into matrix otherwise we can't get the mean...
[r,c] = size(Collected_Data(1).sorted_CRF);
Sortedmatrix = zeros(nFlies,r,c);
for i = 1 : nFlies
    Sortedmatrix(i,:,:) = SortedData(i).sorted_CRF ;
end


%% calculate mean for each phenotype
for phen = 1 : nPhenotypes
    meanCRF(phen,:,:)=squeeze(mean(Sortedmatrix(ia(phen):ib(phen),:,:),1));
end
    
%% Plot mean CRFs
[pathstr, fileName, ext] = fileparts(dirName);

% definition of frequency names is also in anothr filr ...
FreqNames = {'1F1', '1F2', '2F1', '2F2', '1F1+1F2', '2F2+2F2', 'F2-F1' };
nUnMasked=flydata(1).nUnMasked ;

for phen = 1 : nPhenotypes
    figure('Name', strcat(' mean CRFs of: ',fileName, ' Phenotype: ', num2str(phen)));
    
    nPlots = length(FreqNames);
    for i = 1 : nPlots
        
        subplot ( mod(nPlots,4), floor(nPlots/2), i);
        plot (meanCRF(phen, [1:nUnMasked],2), meanCRF(phen, [1:nUnMasked],i+2), '-*', meanCRF(phen, [nUnMasked+1:end],2), meanCRF(phen, [nUnMasked+1:end],i+2), '-.O' );
        ylim([ 0, max(max(meanCRF(:,:,i+2))) ]);
        if (i==1)
            legend('UNmasked', 'Masked', 'Location', 'NorthWest') ;
        end;
        set(gca,'XScale','log');
        title(FreqNames{i});
        
    end
    
    text(150,max(meanCRF(phen, [nUnMasked+1:end],i+2))/2, strrep(['N=', num2str(id(phen)), ' ', C{phen}],'&',' '));
    
    printFilename = [dirName, filesep, fileName, '_', num2str(phen), '_', num2str(iBlock), '_mean_CRF', sExt];
    print( printFilename );
    
end


disp (['done! ', dirName]);

%% write out the max CRF
disp ('Now writing max 1F1 and 2F1');
disp (['Selected repeat :', choice ]);
disp(' ');
for i = 1 : length(Collected_Data)
   myTxt = ['']; 
   for j=1 : length(Collected_Data(i).phenotypes)
      myTxt = [ myTxt, Collected_Data(i).phenotypes{j}, ' '];   
   end
    myTxt = [myTxt,' 1F1=',num2str(Collected_Data(i).sorted_CRF(5,3)),' 2F1=', num2str(Collected_Data(i).sorted_CRF(5,5))]; 
    myTxt = [myTxt, ' ', Collected_Data(i).fileName, ' '];
    disp (myTxt);
end



