clear all;
PsychDefaultSetup(2);
nLevels=11; % How many luminance steps?
WhichScreen=1

win=PsychImaging('Openwindow', WhichScreen, 1);

Screen('TextSize', win, 48);

DrawFormattedText(win, 'GO','center','center');
r1=[0 0 3000 2000]
gunSet=[1,0,0;0,1,0;0,0,1;1,1,1];
contLevels=linspace(0,1,nLevels);
   datadir='C:\data\ScreenCalibration';
        time = now
        
          %% Create MATLAB Instrument OmniDriver Object
        Ocean=icdevice('OceanOptics_OmniDriver.mdd');
        
        %% Conect to Spectrometer
        connect(Ocean);
        disp(Ocean);
        
        %% acquisition parameters
        
        IntergrationTime= 10000; % microseconds; here set to 0.01 seconds
        spectrometerIndex=0;
        channelIndex=0
        enable=1
        scansToAverage=100;
        
        %% Identify Spectrometer
        % how many spectrometers connected?
        numOfSpectrometers = invoke(Ocean, 'getNumberofSpectrometersFound');
        
        display(['Found ' num2str(numOfSpectrometers) 'Ocean Optics spectrometer.']);
        
        % spectrometer name?
        spectrometerName = invoke(Ocean, 'getname', spectrometerIndex);
        
        %serial number?
        
        spectrometerSerialNumber = invoke(Ocean, 'getSerialNumber', spectrometerIndex);
        display(['Model Name : ' spectrometerName])
        display(['Model Serial Number :' spectrometerSerialNumber]);
        
        %% Set Spectrum Acqusition Parameters
        
        % Integration Time
        invoke(Ocean, 'setIntegrationTime', spectrometerIndex, channelIndex, IntergrationTime);
        % Scans to average (increases SNR)
        invoke(Ocean, 'setScansToAverage', spectrometerIndex, channelIndex, 1);
        
        % non-linearity correction
        invoke(Ocean, 'setCorrectForDetectorNonlinearity', spectrometerIndex, channelIndex, enable);
        %correct for 'electrical Dark' noise
        invoke(Ocean, 'setCorrectForElectricalDark', spectrometerIndex, channelIndex, enable);
        %% Aquire Spectrum
        
        wavelengths = invoke(Ocean, 'getWavelengths', spectrometerIndex, channelIndex);
        
for thisGunSet=1:4
    for thisContLevelIndex=1:nLevels
        fprintf('\nGun %d level %d\n',thisGunSet,thisContLevelIndex);
        Screen('FillRect', win, gunSet(thisGunSet,:)*contLevels(thisContLevelIndex),r1,1);
        Screen('Flip',win)
        
        % acquire wavelengths and save into double array
        tic
        for thisScan=1:scansToAverage
            spectralData(:,thisScan)= invoke(Ocean, 'getSpectrum', spectrometerIndex);
        end
        
        toc
        %% Plot
        
        plot (wavelengths,mean(spectralData,2));
        ylabel('intesity')
        xlabel('wavelength(nm)');
        
        meanSpectData(thisGunSet,thisContLevelIndex,:)=mean(spectralData,2);
        beep
    end
end

    %% Clean Up
    
    filename=fullfile(datadir,['test'])
    save(filename);
    
    disconnect(Ocean);
    delete(Ocean);
    
    sca;

    sumPower=squeeze(sum(meanSpectData(:,:,300:1300),3));
    
    sumPower=sumPower-repmat(sumPower(:,1),[1 nLevels]);
    %% Plot the result
    figure(2);
    hold off;
    h=plot(contLevels,sumPower');
    grid on;
    for t=1:4
    set(h(t),'Color',gunSet(t,:)/2);
    set(h(t),'LineWidth',2);
    end
    hold on;
    h2=plot(contLevels,sum(sumPower(1:3,:)),'k');
    set(h2,'LineWidth',3);
    
    xlabel('Normalized LCD gun intensity');
    ylabel('Output intensity (a.u.)');
    
    %% Remaining to do: Fit a gamma function to the curves. The best thing to do here is look at the Psychtoolbox routines for calibration. They will do this last part in a function.
    
  fig5 = CalibratePlotGamma(cla,[h2])
    