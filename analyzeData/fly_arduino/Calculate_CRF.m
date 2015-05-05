function Calculate_CRF (my_meanContrasts,my_meanFFT,pathstr,fileName,bCloseGraphs)

%% Extract fft data
% sample rate was 4 ms, so these numbers are 4 times
FreqNames = GetFreqNames();
% FreqsToExtract = [ F1, F2, 2*F1, 2*F2, F1+F2, 2*(F1+F2), F2-F1 ];
% FreqsToExtract = FreqsToExtract*4 + 1 ;
% this next bit might be written more cleanly, but i want to check we get
% the right section..
FreqsToExtract = [48,60,96,120,108,216,12] ;
[dummy, nFreqs ] = size(FreqsToExtract);

complx_CRF=zeros(9,nFreqs+2);

complx_CRF(:,1)= my_meanContrasts(:,3);
complx_CRF(:,2)= my_meanContrasts(:,2);

for i = 1 : nFreqs
complx_CRF(:,i+2)= my_meanFFT(:,FreqsToExtract(i));
end 

plot_mean_crf (complx_CRF,pathstr,fileName, bCloseGraphs);

