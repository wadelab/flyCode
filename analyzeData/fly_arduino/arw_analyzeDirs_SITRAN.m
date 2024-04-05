close all
baseDir='/raid/data/SITRAN/'
inputDirList={'2024_01_16'};

nGT=length(inputDirList);
for thisGT=1:nGT
    fInputDir=fullfile(baseDir,inputDirList{thisGT});
    offset=thisGT*2-1;
    outData=arw_read_arduino_dir_SITRAN(fInputDir,offset);
end

