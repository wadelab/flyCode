function [outParams]=fly_fitHyperData(params,contRange,dataToFit);
% function fittedCRFParams=fly_fitHyperData(params,contRange,dataToFit)
% Takes a data structure that is nPhenotypes x nPoints and fits a hyperbolic ratio to each phenotype. Returns Rmax, c50, exp, Rzero in fittedParams
nPhenotypes=size(dataToFit,1);
for thisPhenotype=1:nPhenotypes
      [errFun(thisPhenotype),outParams(thisPhenotype,:)]=fit_hyper_ratio(squeeze(contRange(:)),squeeze(abs(dataToFit(thisPhenotype,:))),5,0);
end
    