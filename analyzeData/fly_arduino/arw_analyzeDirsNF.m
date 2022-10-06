close all

inputDirList={'NF1','control_NF1'};

nGT=length(inputDirList);
for thisGT=1:nGT
    fInputDir=inputDirList{thisGT};
    offset=thisGT*2-1;
    arw_read_arduino_dir(fInputDir,offset);
end

