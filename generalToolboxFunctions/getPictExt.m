function [s] = getPictExt ()
% this function returns eps for macs and unices and pdf for PCs

s = '.eps' ;
if ispc
    s = '.pdf' ;
end

