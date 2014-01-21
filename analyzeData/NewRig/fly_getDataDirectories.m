function phenotypeList=fly_getDataDirectories(baseDir)
% phenotypeList=fly_getDataDirectories(baseDir)
% Given a 'base' directory, this function will traverse the directory
% structure finding genotype/phenotype directories (identified with an
% 'all' prefix. Inside these dirs it will find 'Flyxxx' directories and in
% each of these it will find raw data files for a single run of a fly
% experiment.
% The full list of pathnames to the data files will be returned in the cell
% array 'phenotypeList'
% The directory structure must look like this ...
%
%     [baseDir] --- allKCCd1---Fly1---rawFile1.mat
%               |           |      |--rawFile2.mat
%               |           |--Fly2---rawFile1.mat
%               |                  |--rawFile2.mat   
%               |                  |--rawFile3.mat
%               |---allKCCd10---Fly1--rawFile1.mat
%               |           |      |--rawFile2.mat
%               |           |---Fly2--rawFile1.mat
%               |                  |--rawFile2.mat   
%               |                  |--rawFile3.mat
%
%
%
%
%
%
allPTList=dir([baseDir,'/all*']); % List all the directories starting with 'all'

thisPTIndex=0;

for thisPT=1:length(allPTList);
    if  (allPTList(thisPT).isdir)
        thisPTIndex=thisPTIndex+1;
        phenotypeList{thisPTIndex}.dirName=fullfile(baseDir,allPTList(thisPT).name);
        phenotypeList{thisPTIndex}.type=allPTList(thisPT).name;
        
        % Now go into each phenotype and find how many flies...
        flyList=dir([phenotypeList{thisPTIndex}.dirName,'/Fly*']);
        
        flyIndex=0;
        for thisFly=1:length(flyList)
            if(flyList(thisFly).isdir)
                flyIndex=flyIndex+1;
                
                phenotypeList{thisPTIndex}.flyDir{flyIndex}=fullfile(phenotypeList{thisPTIndex}.dirName,flyList(thisFly).name);
                phenotypeList{thisPTIndex}.nFlies=length(flyList);
                
                % At this point, we can delve into the individual fly
                % directories and find out how many reps we ran on each one.
                repeatedMeasureList=dir([phenotypeList{thisPTIndex}.flyDir{flyIndex},'/*.mat'])
                phenotypeList{thisPTIndex}.flyData{flyIndex}.nReps=length(repeatedMeasureList);
                if ((phenotypeList{thisPTIndex}.flyData{flyIndex}.nReps) <1)
                    warning('***---No data files found in this directory:');
                    disp((phenotypeList{thisPTIndex}.flyDir{flyIndex}));
                end
                
                dname=struct2cell(repeatedMeasureList);
                phenotypeList{thisPTIndex}.flyData{flyIndex}.dname=dname;
                for thisDatFile=1:phenotypeList{thisPTIndex}.flyData{flyIndex}.nReps
                phenotypeList{thisPTIndex}.flyData{flyIndex}.fileNames{thisDatFile}=dname{1,thisDatFile};
                end
                
            else
                disp('Not a valid Fly data directory');
            end % End check on Fly directory validity
            
            
            
            
        end % Next fly
        
    else
        disp('Not a directory...');
    end % End check on whether we are looking in a directory at the genotype/phenotype level
    
end % Next genotype

