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
    a=genpath('k:\data\SSERG\toolbox');
    addpath(a);
end

clear all;
close all;

TESTFLAG=0; % Set this to 1 to indicate that we're testing the script without accessing the hardware.
% Remember to set it to '0' for real experiments!

datadir='../data/'; % Where you want the data to be saved. On the acquisition computer it's datadir='E:\data\2012\SSERG\';

interExptPauseSecs = 0;

digitizerSampleRate=1000; % Hz
nOutChans=1; % How many LED outputs do we have? Now I >thought< we had 5 LEDs but I get an error if I set this to 5.

offVoltage=5.5; % Volts. At this level the LED is off. Don't ask why it's not 0...

digitizerAmpMode='Differential';

% Stuff to do with the actual stimulus
binDuration=1; % One second per bin
binsPerTrial=2;  % Average this many bins together for each trial
nPreBins=1; % Add on this many bins at the start of each trial to avoid onset transients.
nTrials=11; % Number of separate trial conditions. This will span the contrast range.

%% Experiment logging
[metaData,Cancelled]=runFlyInputGUI;   % This requires a function inputsdlg, available from the mathworks central website.
if (Cancelled)
    error('Script cancelled');
end

%% At the moment, the different exptSets are all the same except for the
%% channe that is used. set 1 uses channel 0, set 2 uses channel 1 etc...
%%
% Loop over many reps once you are satisfied with the code
% *************************************************************
exptParams=getFlyExptStructRandRig2test(metaData.exptSet); % Get the parameters for all the experiments in a single structure exptParams().
nRepeats=exptParams{1}.nRepeats;

tic
for thisRun=1:nRepeats
    
    % Compute the length of an entire trial
    totalTrialDuration=exptParams{1}.binDuration*(exptParams{1}.binsPerTrial+exptParams{1}.nPreBins); % in Seconds
   
    disp('Running experiment...');
   
    if (~TESTFLAG)    % If we're >not< testing, go ahead and set up the acquisition hardware.
        
        %% INITIALIZE THE RIG
        [ao,ai]=initNIDAQRig2([offVoltage]); %This is a separate function that zeros out all the outputs. Normally we leave the led on between trials to allow the fly to adapt to mean levels
  
        
        %% Here we set up the trials and run them. We will store data on a
        % per-trial basis and chop it up later.
        
        % Data will be acquired from hardware channels 0 and 1. These are the
        % electrode and the photodiode.
        addchannel(ai, 0);
        addchannel(ai, 1);
        set(ai.Channel(1),'InputRange',[-10 10]);
        set(ai.Channel(1),'SensorRange',[-10,10]);
        set(ai.Channel(1),'UnitsRange',[-10 10]);
        %% Set up the input system - we can do this just once per expt: Data will
        % come into the same buffer each time and we can extract it after each
        % trial.
        
        % Configure the analog input
        set(ai,'InputType',digitizerAmpMode);
        ai.SampleRate = digitizerSampleRate; % Rate in samples / second
        ai.SamplesPerTrigger = digitizerSampleRate*totalTrialDuration;
        % Make it a manual trigger and link it to the output trigger
        
        %% Set up the output channels. There are two for now - more perhaps later
        %when we do silent substitution
        % However, there's no reason not to initialize all 5
        chans = addchannel(ao,0:(nOutChans-1));
        set(ao,'SampleRate',digitizerSampleRate);
        ActualRate = get(ao,'SampleRate');
        set([ai ao],'TriggerType','Manual')
        set(ai,'ManualTriggerHwOn','Trigger')
        
    else
        ActualRate=10000;
    end
    
    
    %%
    % Loop over all experiments
    for thisExpt=1:length(exptParams)
        
         disp('Pausing...');
         pause(interExptPauseSecs);
         disp('Running');   
        len = ActualRate*totalTrialDuration; % We do this because the rate we ask for might not be available. However, if it's not, I'd expect trouble.
        
        
        % Stuff that converts between input voltages and contrast
        contVoltRange(:,1)=exptParams{thisExpt}.contRange(:,1)*(offVoltage-exptParams{thisExpt}.baselineVoltage(1)); % For each contrast, this is the corresponding voltage modulation.
        contVoltRange(:,2)=exptParams{thisExpt}.contRange(:,2)*(offVoltage-exptParams{thisExpt}.baselineVoltage(2)); %
        
        % Save these values for logging
        % Expt is a big cell array that stores all the information needed to
        % recreate the stimulus + the resulting data
        
        % Now loop over all trials (contrast levels) setting up the output system
        % and acquiring data each time.
        expt{thisExpt}=metaData;
        
        expt{thisExpt}.startTime=now;
        
        
        for thisTrial=1:exptParams{thisExpt}.nTrials % Loop over all trials. For each trial we reset and recompute the output waveforms.
            
            data=repmat(exptParams{thisExpt}.chanBaselineArray,len,1); % Here we set up the actual output dataarray. The values in chanBaselineArray are set to 'offVoltage' if there's nothing happening on that channel
            
            thisModVoltage(1)=contVoltRange(thisTrial,1);
            thisModVoltage(2)=contVoltRange(thisTrial,2);
            fprintf('\nRunning trial %d of %d  at F1 contrast %d, F2 contrast %d',thisTrial,exptParams{thisExpt}.nTrials, exptParams{thisExpt}.contRange(thisTrial,1),exptParams{thisExpt}.contRange(thisTrial,2));
            %% Now set up the output system

            %
            waveform(:,1)=sin(linspace(0,2*pi*exptParams{thisExpt}.F(1)*totalTrialDuration,len))';
            waveform(:,2)=sin(linspace(0,2*pi*exptParams{thisExpt}.F(2)*totalTrialDuration,len))';
            for t=1:2
                
                if (strcmp(exptParams{thisExpt}.modType{t},'square'))
                    waveform(:,t)=sign(waveform(:,t));
                end
                
                output(:,t)=thisModVoltage(t)*waveform(:,t);
            end
                        
            for thisChannel=1:2 % *** THE LOOP HERE NEEDS IMPROVING - WE ASSUME ONLY TWO CHANNELS FOR NOW BUT THIS COULD CHANGE
                data(:,(exptParams{thisExpt}.LEDChannel(thisChannel)+1))=data(:,(exptParams{thisExpt}.LEDChannel(thisChannel)+1))+output(:,thisChannel);
                data(end,thisChannel)=exptParams{thisExpt}.baselineVoltage(thisChannel); % Turn the LED to mean level at the end
            end
            
            %Do some bounds checking on 'data' - should always be between 0 and
            %offVoltage.
            if (min(data(:))<0 || max(data(:))>offVoltage)
                disp('**** WARNING - output buffer contains out-of-bounds values. This should really be an error... *****');
            end

            if (~TESTFLAG)
                putdata(ao,data(:,1)) % Put the data (waveform) into the object. A column of data for each channel
                
                start([ai ao]) % Initialize the objects
                trigger([ai ao]) % Acqire data
                wait(ao,totalTrialDuration+1); % Wait 'till it's all over
                
                d(:,:,thisTrial,thisExpt)=getdata(ai);
            else  % If we're just testing, fill the output with random numbers.
                d(:,:,thisTrial,thisExpt)=rand(len,2);
            end
            
        end
        
        % Save details of this particular experiment, then move on to the next
        % one.
        expt{thisExpt}.exptParams=exptParams{thisExpt};
        expt{thisExpt}.startTimeString=datestr(expt{thisExpt}.startTime);
        expt{thisExpt}.endTime=now;
        expt{thisExpt}.endTimeString=datestr(expt{thisExpt}.endTime);
        
    end
    
    
    %% Save out the data
    save('temp');
    
    filename=fullfile(datadir,[expt{thisExpt}.FlyID,'_Ch',int2str(exptParams{1}.LEDChannel(1)),'_',int2str(thisRun),'_',datestr(expt{thisExpt}.startTime,30),'.mat'])
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
    condDat=reshape(condDat,[digitizerSampleRate,exptParams{1}.binsPerTrial,2,exptParams{1}.nTrials,length(exptParams)]);
    
    % Compute the average across bins. This throws away bin-to-bin information
    meanCondDat=squeeze(mean(condDat,2));
    %This is samplesperbin * nChannels * nContrasts * nExpts
    % Here we can re-order meanCondDat to generate plots in order of contrast.
    for thisExpt=1:length(exptParams)
        [dummy,sortSeq{thisExpt}]=sort(exptParams{thisExpt}.randSeq(:,1));
        condDat(:,:,:,:,thisExpt)=condDat(:,:,:,sortSeq{thisExpt},thisExpt);
        meanCondDat(:,:,:,thisExpt)=meanCondDat(:,:,sortSeq{thisExpt},thisExpt);
    end
    
    % Image the data
    figure(1); subplot(2,1,1);
    imagesc(squeeze(meanCondDat(:,1,:,1))); colorbar; axis off;
    subplot(2,1,2);
    imagesc(squeeze(meanCondDat(:,2,:,1))); colorbar; axis off;
    colormap hot;
    
    
    
    
    %% Compute FFTs and look at the 1F1 and 1F2 components
    fftData=fft(meanCondDat);
    % disp('1F1 magnitude');
    % disp(abs(squeeze(fftData(1+F1,:,:,:))));
    % disp('2F1 magnitude');
    % disp(abs(squeeze(fftData(1+F1*2,:,:,:))));
    
    % Do the thing below to fit log contrast onto a plot
    
    contRange1=exptParams{1}.contRange(sortSeq{1},1);
    contRange2=contRange1
    
    contRange1(1,:)=0.01;
    contRange2(1,:)=0.01;
    % Compute the distortion in the output, input.
    F1=exptParams{1}.F(1);
    F2=exptParams{2}.F(2);
    
    distortion=abs(squeeze(fftData(1+F1*2,:,:,:)))./abs(squeeze(fftData(1+F1,:,:,:)));
    % Note: the first value (for 0 contrast) is not very meaningful.
    figure(2);
    subplot(1,2,1);hold off;
    f1Plot1=plot(contRange1(:),abs(squeeze(fftData(1+F1,1,:,1))),'k');
    hold on;
    f1Plot2=plot(contRange1(:),abs(squeeze(fftData(1+F1,1,:,2))),'r');
    set(gca,'XScale','Log');
    ylabel('F1 Amplitude');
    xlabel('Contrast');
    grid on
    subplot(1,2,2);
    hold off;
    f2Plot1=plot(contRange1(:),abs(squeeze(fftData(1+F1*2,1,:,1))),'k');
    hold on
    f2Plot2=plot(contRange1(:),abs(squeeze(fftData(1+F1*2,1,:,2))),'r');
    set(gca,'XScale','Log');
    grid on;
    ylabel('F2 Amplitude');
    xlabel('Contrast');
    set(f1Plot1,'LineWidth',2);
    set(f2Plot1,'LineWidth',2);
    set(f1Plot2,'LineWidth',2);
    set(f2Plot2,'LineWidth',2);
    
    % Save this as a JPEG
    imageName=fullfile(datadir,[expt{thisExpt}.FlyID,'_Ch',int2str(exptParams{1}.LEDChannel(1)),'_',int2str(thisRun),'_',datestr(expt{thisExpt}.startTime,30),'.jpg'])
   print(gcf,'-djpeg',imageName);
   
    
    %%
    % Plot some extra figures: Specifically, we'd like to see what a single bin
    % looks like
    figure(3);
    plot(squeeze(meanCondDat(:,1,exptParams{1}.nTrials,2)));
    title('1 Bin of data');
    grid on;
    
    figure(5);
    imagesc(data);
    colorbar;
    title('Last output buffer');
    
end % Outside loop on overall number of repeats


