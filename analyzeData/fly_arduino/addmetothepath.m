function addmetothepath

mydir = mfilename('fullpath')
myroot=strrep(mydir, 'analyzeData/fly_arduino/addmetothepath','')
myroot=strrep(mydir, 'analyzeData\fly_arduino\addmetothepath','')
mytoolbox= [myroot,'generalToolboxFunctions']
addpath(genpath(mytoolbox));

end
