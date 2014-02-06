% FlyCRF
% Generates a flickering stimulus on a single output channel and steps
% through a range on contrasts (and,possibly, baseline luminances)
% Initially we want to just measure a nice CRF.
% Later we will add in more frequencies, contrast masking etc...
% 07/06/12 ARW _ Edited to make the presentation sequence random so that
% we're less susceptible to adaptation effects.
% Oct2_2012 ARW Checked for new series of expts.
%
%
% We will try to stick to the PowerDiva bin, F1,F2 conventions if possible
% to aid later integration with mrCurrent
% Our ADC rate is very high (10khz?). So we can acquire lots of samples /
% sec
% This version for the second rig...


if (~exist('funFlyInputGUI','file'))
    a=genpath('e:\data\SSERG\toolbox\git');
    addpath(a);
end

clear all;
close all;

TESTFLAG=0; % Set this to 1 to indicate that we're testing the script without accessing the hardware.
% Remember to set it to '0' for real experiments!

datadir='e:\data\SSERG\data\'; % Where you want the data to be saved. On the acquisition computer it's datadir='E:\data\2012\SSERG\';

interExptPauseSecs = 0;

digitizerSampleRate=1000; % Hz
outputSampleRate=200; % Hz. Higher rate because we are using PWM to modulate LEDs
outputPWMCarrierRate=20000; % This is highe than the sample rate. The number of levels =outputPWMCarrierRate/outputSampleRate;
nOutChans=4; % How many LED outputs do we have? Now I >thought< we had 5 LEDs but I get an error if I set this to 5.

offVoltage=5.5; % Volts. At this level the LED is off. Don't ask why it's not 0...

digitizerAmpMode='Differential';

% Stuff to do with the actual stimulus
binDuration=1; % One second per bin
binsPerTrial=10;  % Average this many bins together for each trial
nPreBins=1; % Add on this many bins at the start of each trial to avoid onset transients.
nTrials=11; % Number of separate trial conditions. This will span the contrast range.

%% Experiment logging
[exptParams,Cancelled]=fly_runParseInputGui;   % This requires a function inputsdlg, available from the mathworks central website.
if (Cancelled)
    error('Script cancelled');
end

%% At the moment, the different exptSets are all the same except for the
%% channe that is used. set 1 uses channel 0, set 2 uses channel 1 etc...
%%
% Loop over many reps once you are satisfied with the code
% *************************************************************
nRepeats=5;

for thisRun=1:nRepeats
    
    exptParams=fly_getExptStructRig(exptParams); % Get the parameters for all the experiments in a single structure exptParams().
    % We call this within the
    % loop so that subsequent
    % experiments get different
    % randomized sequences
    
    
    
    % Compute the length of an entire trial
    totalTrialDuration=exptParams.binDuration*(exptParams.binsPerTrial+exptParams.nPreBins); % in Seconds
    
    disp('Running experiment...');
    
    if (~TESTFLAG)    % If we're >not< testing, go ahead and set up the acquisition hardware.
        
        %% INITIALIZE THE RIG
        [ao,ai]=initNIDAQ([offVoltage]); %This is a separate function that zeros out all the outputs. Normally we leave the led on between trials to allow the fly to adapt to mean levels
        
        
        %% Here we set up the trials and run them. We will store data on a
        % per-trial basis and chop it up later.
        
        % Data will be acquired from hardware channels 0,1 and 5. These are
        % the two input
        % electrodes and the photodiode.
        channelList=[0 1 5]; % List of hardware (NIDAQ - reference type) input channels.
        
        %% Set up the input system - we can do this just once per expt: Data will
        % come into the same buffer each time and we can extract it after
        % each trialfor thisChannelToInit=1:length(channelList)
        
        for thisChannelToInit=1:length(channelList)
            
            addchannel(ai, channelList(thisChannelToInit));
            % Configure the analog input
            set(ai.Channel(thisChannelToInit),'InputRange',[-10 10]);
            set(ai.Channel(1),'SensorRange',[-10,10]);
            set(ai.Channel(1),'UnitsRange',[-10 10]);
            set(ai,'InputType',digitizerAmpMode);
        end
        
        
        
        ai.SampleRate = digitizerSampleRate; % Rate in samples / second
        ai.SamplesPerTrigger = digitizerSampleRate*totalTrialDuration;
        % Make it a manual trigger and link it to the output trigger
        
        %% Set up the output channels. There are two for now - more perhaps later
        %when we do silent substitution
        % However, there's no reason not to initialize all 4
        chans = addchannel(ao,0:(nOutChans-1));
        set(ao,'SampleRate',outputPWMCarrierRate);
        ActualOutputRate = get(ao,'SampleRate');
        set([ai ao],'TriggerType','Manual')
        set(ai,'ManualTriggerHwOn','Trigger')
        
    else
        ActualOutputRate=outputPWMCarrierRate;
    end
    
    
    %%
    % Loop over all experiments
    
    disp('Pausing...');
    pause(interExptPauseSecs);
    disp('Running');
    len = outputSampleRate*totalTrialDuration; % We do this because the rate we ask for might not be available. However, if it's not, I'd expect trouble.
    
    
    % Stuff that converts between input voltages and contrast.
    % Specifically it works out a maximum voltage modulation that
    % corresponds to a particular contrast given the baseline voltage level
    % and the 'off voltage' that we are using. For example, if baseline is 3V in real units
    % and the 'off voltage' is 5.5 (as it is on the Prysmatix box) then the baselins is sitting at 2.5V above 0
    % and the contrast is
    % For a 50% modulation, you then want a modulation voltage of 1.25 volts around the baseline. For 100% modulation, you want 2.5V
    
    contVoltRange(:,1)=exptParams.contRange(:,1)*(offVoltage-exptParams.baselineVoltage); % For each contrast, this is the corresponding voltage modulation.
    contVoltRange(:,2)=exptParams.contRange(:,2)*(offVoltage-exptParams.baselineVoltage); %
    
    % Save these values for logging
    % Expt is a big cell array that stores all the information needed to
    % recreate the stimulus + the resulting data
    
    % Now loop over all trials (contrast levels) setting up the output system
    % and acquiring data each time.
    expt=exptParams.b;
    
    expt.startTime=now;
    %%
    
    
    for thisTrial=1:length(exptParams.randSeq) % Loop over all trials (a trial is 10 seconds or so of the same contrast). For each trial we reset and recompute the output waveforms.
        
        outputData=zeros(len,nOutChans); % Here we set up the actual output data array: the thing that we send to the NIDAQ. The values in chanBaselineArray are set to 'offVoltage' if there's nothing happening on that channel
        
        % oputputData has  columns corresponding to each LED. To initialize
        % it, we set it to the 'average' voltage level that we want the
        % LEDs to sit at. They modulate around this level....
        
        thisModVoltage(1)=contVoltRange(thisTrial,1);
        thisModVoltage(2)=contVoltRange(thisTrial,2);
        
        fprintf('\nRunning trial %d of %d  at F1 contrast %.2g, F2 contrast %.2g',thisTrial,exptParams.nTrials, exptParams.contRange(thisTrial,1),exptParams.contRange(thisTrial,2));
        % Now set up the output system
        
        for thisF=1:2 % Generate the waveforms that will be used as the F1 and F2 inputs. Each LED listed in the LEDChannels (:,F) will be set to modulate at the sum of these waveforms.
            
            waveform(:,thisF)=sin(linspace(0,2*pi*exptParams.F(thisF).Freq*totalTrialDuration,len))';
            
            if (strcmp(exptParams.modType{thisF},'square')) % Surn a sine wave into a square wave.
                waveform(:,thisF)=sign(waveform(:,thisF));
            end
            
            modulationContrast(:,thisF)=exptParams.contRange(thisTrial,thisF)*waveform(:,thisF);
        end
        % We are still in LED modulation contrast units at this point.
        
        
        for thisChannel=1:nOutChans %
            % For each channel, we look in exptParams.F.LEDs
            % If F(1) is set for that channel, it gets output(1) added to
            % it. If F(2) is set, it also gets output(2) added to it.
            % Finally, if either F(1) or F(2) are set, it gets the baseline
            % voltage added to it...
            % If >neither< F1 or F2 are set for that LED, it runs at zero
            % amplitude (not a mean level)
            for thisF=1:2
                outputData(:,thisChannel)=outputData(:,thisChannel)+modulationContrast(:,thisF)*exptParams.F(thisF).LED(thisChannel);
            end
            
            
            
        end
        
        % To run into the PWM code, outputData must be a contrast
        % running between 0 and 1 (with .5 as the mean).
        outputData=(outputData+1)/2;
        
        % Generate the PWM waveforms corresponding to the 0-1 contrast
        % levels contained in outputData
        outputVoltage=pry_waveformToPWM(outputData,outputSampleRate,outputPWMCarrierRate,100);
        
        
        %Load the data onto the dac
        vScale=5;
        outputVoltage=vScale-outputVoltage*vScale;
        outputVoltage(end,:)=mean(outputVoltage);
        
        % At this stage, set the 'off'channels to offVoltage
        for thisChannel=1:nOutChans
            if (~(exptParams.F(1).LED(thisChannel) | (exptParams.F(2).LED(thisChannel))))
                outputVoltage(:,thisChannel)=offVoltage;
            end
        end
        
        
        
        %Do some bounds checking on 'data' - should always be between 0 and
        %offVoltage.
        if (min(outputVoltage(:))<0 || max(outputVoltage(:))>offVoltage)
            disp('**** WARNING - output buffer contains out-of-bounds values. This should really be an error... *****');
        end
        
        if (~TESTFLAG)
            putdata(ao,outputVoltage) % Put the data (waveform) into the object. A column of data for each channel
            
            start([ai ao]) % Initialize the objects
            trigger([ai ao]) % Acqire data
            wait(ao,totalTrialDuration+1); % Wait 'till it's all over
            
            d(:,:,thisTrial)=getdata(ai);
        else  % If we're just testing, fill the output with random numbers.
            d(:,:,thisTrial)=rand(len,2);
        end
        
    end % Go to the next trial
    %%
    % Save details of this particular experiment, then move on to the next
    % one.
    expt.exptParams=exptParams;
    expt.startTimeString=datestr(expt.startTime);
    expt.endTime=now;
    expt.endTimeString=datestr(expt.endTime);
    
    
    
    
    %% Save out the data - now saves out to top level directory
    save(fullfile(datadir,'temp'));
    if (~exist(datadir,'dir'))
        warning('Data dir does not exist... Making it!');
        madeDirFlag=mkdir(datadir);
        if (~madeDirFlag)
            warning('Could not make data directory - using current dir');
            datadir=pwd;
        end
    end
    
    
    
    
    filename=fullfile(datadir,[int2str(thisRun),'_',datestr(expt.startTime,30),'.mat'])
    save(filename);
    
    % The data are great, but the order of the contrast settings might
    % (probably >is<) randomized.
    % The random sequences are stored in expt{[experiment]}.randSeq(:,[input])
    % When we plot the data, we want to >undo< this randomiztion
    
    % Turn off the NIDAQ
    if (~TESTFLAG)
        initNIDAQ(5.5); %This is a separate function that zeros out all the outputs. Normally we leave the led on between trials to allow the fly to adapt to mean levels
    end
    
    
    %% From this point on, everything is just plotting - it could be moved to
    % another script. It should be self-contained.
    % I think that one of the channels is currently showing the output of the
    % photodiode, the other is showing the output of the ADC that's driving
    % the LED. So one should be a perfect sine wave. The other should be more
    % or less perfect.
    
    
    % Condition it a bit. Chop out bins
    condDat=d((digitizerSampleRate*nPreBins+1):end,:,:);
    
    
    % Reformat into bins
    nActualTrials=length(exptParams.randSeq);
    condDat=reshape(condDat,[digitizerSampleRate,exptParams.binsPerTrial,3,nActualTrials]);
    
    % Compute the average across bins. This throws away bin-to-bin information
    meanCondDat=squeeze(mean(condDat,2));
    %This is samplesperbin * nChannels * nContrasts * nExpts
    % Here we can re-order meanCondDat to generate plots in order of contrast.
    thisExpt=1
    
    [dummy,sortSeq]=sort(exptParams.randSeq);
    condDat=condDat(:,:,:,sortSeq);
    meanCondDat(:,:,:,thisExpt)=meanCondDat(:,:,sortSeq,thisExpt);
    
    
    % Image the data
    figure(1); subplot(2,1,1);
    imagesc(squeeze(meanCondDat(:,1,:))); colorbar; axis off;
    subplot(2,1,2);
    imagesc(squeeze(meanCondDat(:,2,:))); colorbar; axis off;
    colormap hot;
    
    
    
    
    %% Compute FFTs and look at the 1F1 and 1F2 components
    fftData=fft(meanCondDat);
    % disp('1F1 magnitude');
    % disp(abs(squeeze(fftData(1+F1,:,:,:))));
    % disp('2F1 magnitude');
    % disp(abs(squeeze(fftData(1+F1*2,:,:,:))));
    
    % Do the thing below to fit log contrast onto a plot
    
    contRange=exptParams.contRange(sortSeq,1);
    
    
    contRange(1)=0.01;
    contRange((exptParams.nTrials+1))=0.01;
    % Compute the distortion in the output, input.
    F1=exptParams.F(1).Freq;
    F2=exptParams.F(2).Freq;
    
    
    %% Note: the first value (for 0 contrast) is not very meaningful.
    figure(2);
    for chanToPlot=1:3
        
        subplot(3,2,(chanToPlot-1)*2+1);hold off;
        f1Plot1=plot(contRange(1:exptParams.nTrials),abs(squeeze(fftData(1+F1,chanToPlot,1:exptParams.nTrials))),'k');
        hold on;
        f1Plot2=plot(contRange((exptParams.nTrials+1):end),abs(squeeze(fftData(1+F1,chanToPlot,(exptParams.nTrials+1):end))),'r');
        set(gca,'XScale','Log');
        ylabel('F1 Amplitude');
        xlabel('Contrast');
        legend({'Unmasked','Masked'});
        grid on
        subplot(3,2,(chanToPlot-1)*2+2);hold off;
        hold off;
        
        f1_2Plot1=plot(contRange(1:exptParams.nTrials),abs(squeeze(fftData(1+2*F1,chanToPlot,1:exptParams.nTrials))),'k');
        hold on;
        f1_2Plot2=plot(contRange((exptParams.nTrials+1):end),abs(squeeze(fftData(1+2*F1,chanToPlot,(exptParams.nTrials+1):end))),'r');
        set(gca,'XScale','Log');
        grid on;
        ylabel('2F1 Amplitude');
        xlabel('Contrast');
        legend({'Unmasked','Masked'});
        set(f1Plot1,'LineWidth',2);set(f1Plot2,'LineWidth',2);
        set(f1_2Plot2,'LineWidth',2); set(f1_2Plot1,'LineWidth',2);
        
    end
    % Save this as a JPEG
    imageName=fullfile([datadir,int2str(thisRun),'_',datestr(expt.startTime,30),'.jpg'])
    print(gcf,'-djpeg',imageName);
    
    
    %%
    % Plot some extra figures: Specifically, we'd like to see what a single bin
    % looks like
    figure(3);
    plot(squeeze(meanCondDat(:,1,1)));
    title('1 Bin of data');
    grid on;
    
    figure(5);
    imagesc(outputData);
    colorbar;
    title('Last output buffer');
    
end % Outside loop on overall number of repeats


