function subDirList=fly_getDataDirectoriesOrig(baseDir)
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
        
        subDirList_element.dirName=fullfile(baseDir,allSubDirList(thisSubDir).name);
        subDirList_element.type=allSubDirList(thisSubDir).name;
        
        % Now go into each phenotype and find how many expts...
        exptList=dir([subDirList_element.dirName,'/Fly*']);
         
        
        exptIndex=0;
        subDirList_element.nFlies=0;
        for thisExpt=1:length(exptList)
            if(exptList(thisExpt).isdir)
                
                
                ff=fullfile(subDirList_element.dirName,exptList(thisExpt).name);
                
                
                % At this point, we can delve into the individual expt
                % directories and find out how many reps we ran on each
                % one. Note - each expt now contains data from more than a
                % single fly
                repeatedMeasureList=dir([ff,'/*.mat']);
                nMats = length(repeatedMeasureList);
                
                if (nMats <1)
                    warning('***---No data files found in this directory:');
                    disp(ff);
                else
                    exptIndex=exptIndex+1;
                    subDirList_element.flyDir{exptIndex}=ff;
                    subDirList_element.nFlies=subDirList_element.nFlies+1;
                    subDirList_element.flyData{exptIndex}.nReps=nMats ;
                    dname=struct2cell(repeatedMeasureList);
                    subDirList_element.flyData{exptIndex}.dname=dname;
                    for thisDatFile=1:subDirList_element.flyData{exptIndex}.nReps
                        subDirList_element.flyData{exptIndex}.fileNames{thisDatFile}=dname{1,thisDatFile};
                    end
                
                end
            else
                disp('Not a valid Experimental data directory');
            end % End check on expt directory validity
            
            
        end % Next expt
        if subDirList_element.nFlies > 0
            thisSubDirIndex=thisSubDirIndex+1;
            subDirList{thisSubDirIndex} = subDirList_element ;
            clear subDirList_element ;
        end
    else
        disp('Not a directory...');
    end % End check on whether we are looking in a directory at the genotype/phenotype level
    
end % Next genotype

