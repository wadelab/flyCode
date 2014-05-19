close all
clear all

datadir='C:\data\ScreenCalibration';
time = now

%% Create MATLAB Instrument OmniDriver Object
Ocean=icdevice('OceanOptics_OmniDriver.mdd');

%% Conect to Spectrometer
connect(Ocean);
disp(Ocean);

%% acquisition parameters

IntergrationTime= 100 * 1000; % miliseconds?
spectrometerIndex=0;
channelIndex=0
enable=1

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
% non-linearity correction
invoke(Ocean, 'setCorrectForDetectorNonlinearity', spectrometerIndex, channelIndex, enable);
%correct for 'electrical Dark' noise
invoke(Ocean, 'setCorrectForElectricalDark', spectrometerIndex, channelIndex, enable);

%% Aquire Spectrum

wavelengths = invoke(Ocean, 'getWavelengths', spectrometerIndex, channelIndex);

% acquire wavelengths and save into double array

spectralData= invoke(Ocean, 'getSpectrum', spectrometerIndex);

%% Plot

plot (wavelengths,spectralData);
ylabel('intesity')
xlabel('wavelength(nm)');

%% Clean Up

filename=fullfile(datadir,['green'])
save(filename);

disconnect(Ocean);
delete(Ocean);

