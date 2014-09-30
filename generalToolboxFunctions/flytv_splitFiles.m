function dummy=flytv_splitFiles(inputDir,baseName)
% function dummy=flytv_splitFiles(inputDir,baseName)
% Trawls through a directory and finds files of the form flyTV_*.mat
% Loads each one in one by one and looks for a .data field. If this is
% x*y*z*2 then saves out two separate files of form baseName_[1/2]_*.mat
% Containing data(:,:,:,1) and data(:,:,:,2)
% This is so we can analyze two-fly expts just like we did the 1-fly expts
% E.g. 
% dummy=flytv_splitFiles('C:\data\SSERG\data\NewSweep\PINK1\7DPE\THG2019S\','flyTVsplit_'
% ARW 30/9/2014
if (nargin<2)
    baseName='flyTVsplit_';
end

cwd=pwd;
cd(inputDir);
dList=dir('flyTV*.mat');
nFiles=length(dList);
dummy=0;
if (nFiles<1)
    disp('No files found in directory');
    dist(inputDir);
    
else
    for thisFile=1:nFiles
        fileName=(dList(thisFile).name);
        d=load(fileName);
        if(isfield(d,'data'))
            disp('Data field found');
            [x]=size(d.data);
            if (length(x)==4)
                nFlies=x(4);
                if (nFlies==2)
                    disp('Found two flies! - Splitting them up');
                    for thisFly=1:2
                        d2=d;
                        d2.data=d2.data(:,:,:,thisFly);
                        d2.comment2=sprintf('Split from a single file %s',fileName);
                        d2.splitDate=now;
                        
                        % Chop out the bit after the flyTV_ part
                        datePart=fileName(7:end);
                        
                        fName=sprintf('%s_%d_%s',baseName,thisFly,datePart);
                        save(fName,'-struct','d2');
                        disp(fName);
                        dummy=1;
                    end % Next fly
                    
                end % End check on number of flies
            end % End check on dimensionality of the data
        end % End check on existence of data 
    end % Next file in the directory
end % End check on number of files in the directory
disp('Returning...');
cd (cwd);
return

                        
        