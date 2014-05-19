startTime=now;
close all;
clear all;
clear mex;
DOCALIBRATION=1;

nLevels=8; % How many luminance steps?
%% Create MATLAB Instrument OmniDriver Object
Ocean=icdevice('OceanOptics_OmniDriver.mdd');

%% Conect to Spectrometer
connect(Ocean);
disp(Ocean);

%% acquisition parameters

IntergrationTime= 50000; % microseconds; here set to 0.01 seconds
spectrometerIndex=0;
channelIndex=0
enable=1
scansToAverage=1;

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
f=sin(linspace(0,2*pi*600,4000));

wavelengths = invoke(Ocean, 'getWavelengths', spectrometerIndex, channelIndex);



if (DOCALIBRATION)
    %% Now set up the screen
WhichScreen=1

PsychDefaultSetup(2);
win=PsychImaging('Openwindow', WhichScreen, 1);

%Screen('TextSize', win, 48);

HideCursor;
oldClut = LoadIdentityClut(win, 1);


r1=[0 0 3000 2000]
gunSet=[1,0,0;0,1,0;0,0,1;1,1,1];
contLevels=linspace(0,1,nLevels);
datadir='C:\data\ScreenCalibration';
time = now


Screen('FillRect', win, gunSet(1,:)*contLevels(1));
Screen('Flip',win,[],1);

    
    for thisGunSet=1:4
        Screen('FillRect', win, gunSet(thisGunSet,:)*contLevels(1));
        Screen('Flip',win,[],1);
        for thisContLevelIndex=1:nLevels
            fprintf('\nGun %d level %d\n',thisGunSet,thisContLevelIndex);
            Screen('FillRect', win, gunSet(thisGunSet,:)*contLevels(thisContLevelIndex));
            Screen('Flip',win,[],1)
            pause(1);
            Screen('FillRect', win, gunSet(thisGunSet,:)*contLevels(thisContLevelIndex));
            Screen('Flip',win,[],1)
            pause(1);
            % acquire wavelengths and save into double array
            sound(f,8000)
            tic
            for thisScan=1:scansToAverage
                spectralData(:,thisScan)= invoke(Ocean, 'getSpectrum', spectrometerIndex);
            end
            pause(1);
            disp('Scan acquired...');
            
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
    Screen('CloseAll');
    filename=fullfile(datadir,['test'])
    save(filename);
    
    
    
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
    
    
    % Save out the data
    save('CalibrationData_190514.mat','sumPower','spectralData','meanSpectData','nLevels','contLevels');
    
    
else
    load('CalibrationData_190514.mat');
end

%% Remaining to do: Fit a gamma function to the curves. The best thing to do here is look at the Psychtoolbox routines for calibration. They will do this last part in a function.

% Set Parameters
%plot
% blank array for input values
my_values_in = transpose(linspace(0,1,nLevels));
my_values_out = transpose(linspace(0,1,256));
%
Raw_measurements = transpose(sumPower);
Norm_measurements = NormalizeGamma(Raw_measurements);

fitType = 2 ;  %%'crtLinear'
%%

[gammaFit,gammaParams,fitComment] = FitGamma(my_values_in,Norm_measurements(:,1:3),my_values_out,fitType);

%%

igt=InvertGammaTable(linspace(0,1,256)',gammaFit,256);
figure(4);
subplot(2,1,1);
hold off;
plot(gammaFit);
hold on;
plot(igt);
subplot(2,1,2);
hold off;
%plot(linspace(0,1,256)'.*gammaFit(:,1).*igt(:,1));

%%

    %% Now set up the screen again and set the gamma with the fits
WhichScreen=1

PsychDefaultSetup(2);
win=PsychImaging('Openwindow', WhichScreen, 1);

HideCursor;


r1=[0 0 3000 2000]
gunSet=[1,0,0;0,1,0;0,0,1;1,1,1];
contLevels=linspace(0,1,nLevels);
datadir='C:\data\ScreenCalibration';
time = now


%Screen('FillRect', win, gunSet(1,:)*contLevels(1));
%Screen('Flip',win,[],1);
%Screen('LoadNormalizedGammaTable',WhichScreen,igt);
Screen('LoadNormalizedGammaTable',WhichScreen,igt);


% Now redo the calibration with the new gamma table

Screen('FillRect', win, gunSet(1,:)*contLevels(1));
Screen('Flip',win,[],1);
for thisGunSet=1:4
    Screen('FillRect', win, gunSet(thisGunSet,:)*contLevels(1));
    Screen('Flip',win,[],1);
    for thisContLevelIndex=1:nLevels
        fprintf('\nGun %d level %d\n',thisGunSet,thisContLevelIndex);
        Screen('FillRect', win, gunSet(thisGunSet,:)*contLevels(thisContLevelIndex));
        Screen('Flip',win,[],1)
        pause(1);
        Screen('FillRect', win, gunSet(thisGunSet,:)*contLevels(thisContLevelIndex));
        Screen('Flip',win,[],1)
        pause(1);
        % acquire wavelengths and save into double array
        sound(f,8000)
        tic
        for thisScan=1:scansToAverage
            spectralData2(:,thisScan)= invoke(Ocean, 'getSpectrum', spectrometerIndex);
        end
        pause(1);
        disp('Scan acquired...');
        
        toc
        %% Plot
        
        plot (wavelengths,mean(spectralData2,2));
        ylabel('intesity')
        xlabel('wavelength(nm)');
        
        meanSpectData2(thisGunSet,thisContLevelIndex,:)=mean(spectralData2,2);
        beep
        
    end
end


sumPower2=squeeze(sum(meanSpectData2(:,:,300:1300),3));

sumPower2=sumPower2-repmat(sumPower2(:,1),[1 nLevels]);
%% Plot the result
figure(12);
hold off;
h=plot(contLevels,sumPower2');
grid on;
for t=1:4
    set(h(t),'Color',gunSet(t,:)/2);
    set(h(t),'LineWidth',2);
end
hold on;
h2=plot(contLevels,sum(sumPower2(1:3,:)),'k');
set(h2,'LineWidth',3);

xlabel('Normalized LCD gun intensity');
ylabel('Output intensity (a.u.)');


disconnect(Ocean);
delete(Ocean);
sca
endTime=now-startTime;
disp(endTime)
