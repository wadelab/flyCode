function igt=fly_computeInverseGammaFromCalibFile(cFile)
%  igt=fly_computeInverseGammaFromCalibFile(cFile)
% Our calibration script saves out the photometer values at different DAC
% levels
% This function reads that info in, computes an inverse gamma function and
% returns it ready to pass into LoadNormalizedGamma

load(cFile);
fitType = 2 ;  %%'crtLinear'
my_values_in = transpose(linspace(0,1,nLevels));
my_values_out = transpose(linspace(0,1,256));
Raw_measurements = transpose(sumPower);
Norm_measurements = NormalizeGamma(Raw_measurements);
[gammaFit,gammaParams,fitComment] = FitGamma(my_values_in,Norm_measurements(:,1:3),my_values_out,fitType);

%%

igt=InvertGammaTable(linspace(0,1,256)',gammaFit,256);
