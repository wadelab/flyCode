function addmetothepath

mydir = mfilename('fullpath')
mytoolbox= [mydir,'../../generalToolboxFunctions/']
addpath(genpath(mytoolbox));

end
