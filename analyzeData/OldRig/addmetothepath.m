function addmetothepath

mydir = mfilename('fullpath')
myroot=strrep(mydir, 'analyzeData/OldRig/addmetothepath','')
myroot=strrep(myroot, 'analyzeData\OldRig\addmetothepath','')
mytoolbox= [myroot,'generalToolboxFunctions']
addpath(genpath(mytoolbox));

end
