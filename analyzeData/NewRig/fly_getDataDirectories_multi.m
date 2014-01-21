function subDirList=fly_getDataDirectories(baseDir)
% subDirList=fly_getDataDirectories(baseDir)
% Given a 'base' directory, this function will traverse the directory
% structure finding genotype/phenotype directories (identified with an
% 'all' prefix. Inside these dirs it will find 'Flyxxx' directories and in
% each of these it will find raw data files for a single run of a fly
% experiment.
% The full list of pathnames to the data files will be returned in the cell
% array 'subDirList'
% The directory structure must look like this ...
%
%     [baseDir] --- allKCCd1---Expt1---rawFile1.mat
%               |           |      |--rawFile2.mat
%               |           |--Expt2---rawFile1.mat
%               |                  |--rawFile2.mat   
%               |                  |--rawFile3.mat
%               |---allKCCd10---Expt1--rawFile1.mat
%               |           |      |--rawFile2.mat
%               |           |---Expt2--rawFile1.mat
%               |                  |--rawFile2.mat   
%               |                  |--rawFile3.mat
%
%
%
%
%
%
allSubDirList=dir([baseDir,'/all*']); % List all the directories starting with 'all'

thisSubDirIndex=0;

for thisSubDir=1:length(allSubDirList);
    if  (allSubDirList(thisSubDir).isdir)
        thisSubDirIndex=thisSubDirIndex+1;
        subDirList{thisSubDirIndex}.dirName=fullfile(baseDir,allSubDirList(thisSubDir).name);
        subDirList{thisSubDirIndex}.type=allSubDirList(thisSubDir).name;
        
        % Now go into each phenotype and find how many expts...
        exptList=dir([subDirList{thisSubDirIndex}.dirName,'/Expt*']);
        
        exptIndex=0;
        for thisExpt=1:length(exptList)
            if(exptList(thisExpt).isdir)
                exptIndex=exptIndex+1;
                
                subDirList{thisSubDirIndex}.exptDir{exptIndex}=fullfile(subDirList{thisSubDirIndex}.dirName,exptList(thisExpt).name);
                subDirList{thisSubDirIndex}.nFlies=length(exptList);
                
                % At this point, we can delve into the individual expt
                % directories and find out how many reps we ran on each
                % one. Note - each expt now contains data from more than a
                % single fly
                repeatedMeasureList=dir([subDirList{thisSubDirIndex}.exptDir{exptIndex},'/*.mat'])
                subDirList{thisSubDirIndex}.exptData{exptIndex}.nReps=length(repeatedMeasureList);
                if ((subDirList{thisSubDirIndex}.exptData{exptIndex}.nReps) <1)
                    warning('***---No data files found in this directory:');
                    disp((subDirList{thisSubDirIndex}.exptDir{exptIndex}));
                end
                
                dname=struct2cell(repeatedMeasureList);
                subDirList{thisSubDirIndex}.exptData{exptIndex}.dname=dname;
                for thisDatFile=1:subDirList{thisSubDirIndex}.exptData{exptIndex}.nReps
                subDirList{thisSubDirIndex}.exptData{exptIndex}.fileNames{thisDatFile}=dname{1,thisDatFile};
                end
                
            else
                disp('Not a valid Experimental data directory');
            end % End check on expt directory validity
            
            
            
            
        end % Next expt
        
    else
        disp('Not a directory...');
    end % End check on whether we are looking in a directory at the genotype/phenotype level
    
end % Next genotype

