load('/Users/alexwade/Downloads/Sweep1 08.04.14.mat') % it is possible to browse files using uigetfile
[fName,pName]=uigetfile('*.mat','Load flyTV data');
dataSet=fullfile(pName,fName); % Fullfile generates a legal filename on any platform

[nTF,nSF]=size(dataSet);
nSecs=20;

for thisTF=1:nTF
    for thisSF=1:nSF
        allRespData=dataSet{thisTF,thisSF};
        timeSeriesData=allRespData.Data(1001:end);
        fTSData=fft(timeSeriesData);
        inputFreq=tfList(thisTF);
        outAmplitude2F1(thisTF,thisSF)=fTSData(inputFreq*2*nSecs+1); % Remember, adding 1 to allow for 0 freq in FFT
        outAmplitude1F1(thisTF,thisSF)=fTSData(inputFreq*1*nSecs+1); % Remember, adding 1 to allow for 0 freq in FFT
        outNoise(thisTF,thisSF)=sqrt(sum(abs(fTSData(2:1000).^2)));
    end
end

% We can take a quick look like this...
figure(1);
subplot(2,2,1);
imagesc(abs(outAmplitude2F1))
colorbar
colormap hot;
xlabel('Spatial Frequency (a.u.)');
ylabel('Temporal Frequency (a.u.)');
% A better thing to do is to compute the 'coherence' - the power at the
% frequency of interest divided by some local measure of noise
subplot(2,2,2);
imagesc(abs(outNoise));
xlabel('Spatial Frequency (a.u.)');
ylabel('Temporal Frequency (a.u.)');
colorbar
colormap hot;
subplot(2,2,3);



imagesc(abs(outAmplitude1F1)./outNoise);

colorbar
colormap hot;
xlabel('Spatial Frequency (a.u.)');
ylabel('Temporal Frequency (a.u.)');
subplot(2,2,4);



imagesc(abs(outAmplitude2F1)./outNoise);

colorbar
colormap hot;
xlabel('Spatial Frequency (a.u.)');
ylabel('Temporal Frequency (a.u.)');
