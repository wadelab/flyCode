close all
baseDir='/raid/data/SITRAN/'
inputDirList={'CA','DN','elav_ssg'};

nGT=length(inputDirList);
for thisGT=1:nGT
    fInputDir=inputDirList{thisGT};
    offset=thisGT*2-1;
    arw_read_arduino_dir(fInputDir,offset);
end

