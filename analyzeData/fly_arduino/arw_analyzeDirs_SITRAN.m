close all
baseDir='/groups/labs/wadelab/data/sitran/flyArduino2'
baseDir='/raid/data/SITRAN/flyData/flyArduino2/CSOR_Pink1_W1118'

%inputDirList={'W1118CS_1dpe','W1118CS_3dpe','W1118CS_7dpe'};
inputDirList={'Pink1B9_1dpe','Pink1B9_7dpe','Pink1B9_14dpe'};
nGT=length(inputDirList);

for thisGT=1:nGT
    fInputDir=fullfile(baseDir,inputDirList{thisGT});
    
    offset=thisGT*2-1;
    outData=arw_read_arduino_dir_SITRAN(fInputDir,offset,1);
end

