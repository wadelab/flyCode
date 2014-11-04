nConds=9;
nReps=10;
nSecs=4;
nJunkSecs=1;
sampleRate=256;
signalFreq=16; % HZ

dStat=zeros(sampleRate*(nSecs),4,nConds);

for thisRun=1:nReps
    for thisCond=1:nConds
        thisData=finalData.data{thisRun,thisCond};
        dStat(:,:,thisCond)=dStat(:,:,thisCond)+thisData;
    end
end


cropStat=dStat((sampleRate*nJunkSecs+1):end,:,:);
% Reshape into bins
cropStat=reshape(cropStat,[sampleRate,(nSecs-nJunkSecs),4,nConds]);

fCrop=abs(fft(cropStat));
% Compute coherent mean
mfCrop=squeeze(mean(fCrop,2));

oAmp=squeeze(mfCrop((signalFreq)+1,:,:));
sideBars=squeeze(mfCrop([ 14 ,12],:,:));
coh=abs(oAmp)./squeeze(sum(abs(sideBars)));
figure(1);

bar(abs(oAmp));

figure(2);
bar(squeeze(abs(mfCrop(2:60,2,:))));

