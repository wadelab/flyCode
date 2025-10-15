clear global;
warning('off', 'all');
% Load SNIRF data
root_dir = 'E:\fNIRS_2025\Abi_fNIRS\Data';
raw = nirs.io.loadDirectory([root_dir filesep 'NIRS'], {'Subject'}); 

% Visualize demographics and probe
demographics = nirs.createDemographicsTable(raw);

%% Discard extra stimuli 
jobs = nirs.modules.DiscardStims();
jobs.listOfStims = { ...
    'A'; 'B'; 'C'; 'D'; 'E'; 'F'; 'G'; 'H'; 'I'; 'J'; 'K'; 'L'; 'M' ...
    };
raw = jobs.run(raw);
%raw = nirs.viz.StimUtil(raw);
raw(1).probe.draw;

%% Step 1: Run QT
jobs = nirs.modules.QT();
jobs.qThreshold =0.50;
jobs.fCut = [0.5 2.0];
ScansQuality = jobs.run(raw);
ScansQuality.drawGroup('sqmask');
ScansQuality.drawGroup('bar');

pause;

%% Step 2: Trim Baseline
jobs = nirs.modules.TrimBaseline();
jobs.preBaseline = 5;    % 5 sec before first event
jobs.postBaseline = 15;  % 15 sec after last event
raw = jobs.run(raw);

%% Step 3 - Label short separation channels for later extraction (regressors)
jobs = nirs.modules.LabelShortSeperation();
jobs.max_distance = 21;
raw = jobs.run(raw);

% jobs = nirs.modules.RemoveShortSeperations(); % this removes the SSC channel from the probe design
% raw_with_stim = jobs.run(raw_with_stim);
raw(7).probe.draw;

%% Step 4: Convert AUX to Stimulus and add to raw data = create own file for this but could use AuxToStim() from NIRS = Mel FUNCTION
raw_with_stim = convertAux8HybridA(raw);% Corrently collecting 56 samples of ~11-12s trials? = nope as dropped signals :-(
%raw_with_stim = convertAux8Hybrid(raw, 'pulses')% pulses detects the very short duration TTLs whereas 'blocks' detects longer duration TTLs
% figure(3);
disp(raw_with_stim(1).stimulus.keys);
raw_with_stim(7).draw;


%% Step 5: Create Stimulus events from PsychoPy xlsx data
% load premade tables R1, R2, ..., R10 into the workspace
load('Psychopy_stim.mat');

%% Step 6: Use condition labels generated above and allign with AUX8 events - plot these = Mel FUNCTION
raw_with_stim = alignAuxWithStimHybrid(raw_with_stim, 10, 'align_log.txt', 8);
% raw_out = alignAuxWithStimHybrid(raw_in, nParticipants, logFile, expectedBlocks)
pause;

%% Step 6a: rename stimulus event for normalization i.e. remove "." and replace with "_"
% Define your renaming map: old names → new names
job = nirs.modules.RenameStims();
job.listOfChanges = {
    'G0.25_M0.00', 'G0_25_M0_00';
    'G0.06_M0.00', 'G0_06_M0_00';
    'G0.00_M0.30', 'G0_00_M0_30';
    'G1.00_M0.00', 'G1_00_M0_00';
    'G0.06_M0.30', 'G0_06_M0_30';
    'G0.12_M0.30', 'G0_12_M0_30';
    'G0.50_M0.30', 'G0_50_M0_30';
    'G0.12_M0.00', 'G0_12_M0_00';
    'G0.25_M0.30', 'G0_25_M0_30';
    'G0.50_M0.00', 'G0_50_M0_00';
    'G0.00_M0.00', 'G0_00_M0_00'
};
job = nirs.modules.DiscardStims(job);
job.listOfStims = {'aux8_pulses'};
raw_with_stim = job.run(raw_with_stim);

%% Step 7: Convert  data to HbO and HbR signals using MBLL 
jobs = nirs.modules.OpticalDensity(); % convert to optical density
jobs = nirs.modules.Resample(jobs); % downsample data for faster analysis (Fs = 1 = very fast)
jobs.Fs = 1;
jobs = nirs.modules.BeerLambertLaw(jobs);
hb = jobs.run(raw_with_stim);

%% Step 8: Filter and remove noise before running GLM
jobs = nirs.modules.BandPassFilter(); % Apply a bandpass filter for HR and respiratory signals
jobs.lowpass = 0.3; jobs.highpass = 0.01;
% Add short-separation regression
%
% jobs = nirs.modules.RemoveShortSeperationRegressors(jobs); % Should we do this? SSC = 21cm = too deep????

glm = nirs.modules.GLM(jobs);
glm.type = 'AR-IRLS';
%glm.AddShortSepRegressors = true;
glm.verbose = true;
SubStats = glm.run(hb);

%cleanDemo = table(demographics.Subject, 'VariableNames', {'Subject'});
jobs = nirs.modules.AddDemographics();
jobs.varToMatch = 'Subject';
jobs.demoTable = demographics; 
SubStats = jobs.run(SubStats);

%% Step 9: Run Group Stats Analysis and visualization
% mixed effects model

jobs = nirs.modules.MixedEffects();
jobs.formula = 'beta ~ cond + (1|Subject)';  % Random intercept for Subject
jobs.dummyCoding = 'effects';  % Optional
GroupStats = jobs.run(SubStats);

%% Extract betas for table comparisons in Excel = Mel's FUNCTION
combinedTable = extractMeanBetaByDetector(SubStats);

%% NB: Maybe Plot the HRF  
HRF = SubStats.HRF;  % the "HRF" command will return the time series from the stats variable.  This also works for 
                        % all the other canonical models (although obviously a canonical model will have a trivial
                        % shape)
                    
nirs.viz.plot2D(HRF(1,1));  % this will plot overlain on the probe layout of a single subject
GroupStats.draw('tstat', [-10 10], 'q < 0.05'); %false discovery rate (FDR) mixed effects
GroupStats.getCritT('q < 0.05'); % Q is the false-discovery rate 
% You can also display a table of all stats
disp(GroupStats.table());
Group = GroupStats.table();

%% Other filtering options: This example specifies DCT terms with a frequency cutoff of 0.08 = filtering.
% %NB instead the SSC to use as a filter here?
% jobs = @(t) nirs.design.trend.dctmtx(t, 0.8);
% jobs = @(t) nirs.design.trend.legendre(t, 3);
% 
% 
% % %Let's use the DCT regressor for now;
% plot(jobs([0:60]')); % will plot the DCT for

% %% Now to get the groups HDR average and plot it
% jobs = nirs.modules.Run_HOMER2(); % start a new job pipeline
% jobs.fcn = 'hmrBlockAvg';
% tpre = -5;
% tpost = 10;
% jobs.vars.trange = [tpre tpost];
% HDR = jobs.run(Raw_pruned);
% HDR.gui; % plots average HDR for each condition

%% Step 10: Run the contrasts to find significant differences between conditions
% We are usually interested in differences between groups or conditions.
% First, look at what the conditions (regression variables) are:
disp(GroupStats.conditions);
c = [eye(11);  % all 11 conditions of the original variables i.e. compare mask against no mask across all Grating Frequencies
     0    -1     1     0     0     0     0     0     0     0     0
     0     0     0    -1     1     0     0     0     0     0     0
     0     0     0     0     0    -1     1     0     0     0     0
     0     0     0     0     0     0     0    -1     1     0     0
     0     0     0     0     0     0     0     0     0    -1     1     
]; % Mask versus no mask

% Calculate stats with the ttest function
ContrastStats = GroupStats.ttest(c);
disp(ContrastStats.table());
Contrast = ContrastStats.table();

ContrastStats.draw('tstat', [-10 10], 'p < 0.05'); % displays the group level tstats = T values

%% Finally, let's save the figures as eps files for closer inspection and/or
% making manuscript figures. Can also use tif or jpg.
%close all;  

folder = [root_dir filesep 'NIRS_results' filesep 'figures'];
ContrastStats.printAll('tstat', [-10 10], 'q < 0.05', folder, 'tif');
% The printAll command also will work for the GroupStats and SubjStats
% variables above.

%% Region of interest tables
% Define ROIs based on source-detector pairs
Region = {};

% ROI 1: Specific source-detector pairs
MeasList = [1 1; 2 1; 5 1; 6 1; 1 2; 2 2; 3 2; 4 2];
Region{1} = table(MeasList(:,1), MeasList(:,2), 'VariableNames', {'source','detector'});

% ROI 2: All detectors connected to detector 1
MeasList = [NaN 2]; % NaN means "all detectors"
Region{2} = table(MeasList(:,1), MeasList(:,2), 'VariableNames', {'source','detector'});

% ROI 3: All detectors connected to detector 2
MeasList = [NaN 2];
Region{3} = table(MeasList(:,1), MeasList(:,2), 'VariableNames', {'source','detector'});

% Compute ROI averages
ROItable = nirs.util.roiAverage(ContrastStats, Region, {'ROI1','ROI2','ROI3','ROI4'});

% Display ROI results
disp(ROItable);

%% ROC analysis not figured this out yet !!
ROC = nirs.testing.ChannelStatsROC;
ROCtest.simfunc=@()nirs.testing(raw_with_stim(randi(length(raw_with_stim),1,1)));
ROC.pipeline=nirs.modules.default_modules.group_analysis;
ROC=ROC.run(5); % maybe should run more but takes longer :-)
ROC.draw;

%% Saving and loading variables
save('E:\fNIRS_2025\Abi_fNIRS\Analysis', 'raw_with_stim', 'hb', 'HRF', 'SubjStats', ...
     'GroupStats', 'Contrast', 'Group', 'ROC', 'ROItable', 'demographics', 'ContrastStats');
