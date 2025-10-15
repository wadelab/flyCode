function raw_out = alignAuxWithStimHybrid(raw_in, nParticipants, logFile, expectedBlocks)
% Aligns stimulus tables with fNIRS aux pulses using a hybrid approach:
% - Removes early outlier TTL pulses
% - Filters aux pulses to remove duplicates/noise
% - Uses real aux timing first, fills/truncates if mismatched
% - Adds QC plots and logs

    raw_out = raw_in;
    fid = fopen(logFile, 'w');
    fprintf(fid, 'Alignment QC Log\n=================\n');

    trialSpacing = 22;   % seconds between trials
    trialDuration = 12;  % seconds per trial
    expectedGap = 21;    % expected gap between trials (s)

    for i = 1:nParticipants
        fprintf('\nProcessing Participant %d...\n', i);
        fprintf(fid, '\nParticipant %d:\n', i);

        % ✅ Check for aux8_pulses
        if ~ismember('aux8_pulses', raw_out(i).stimulus.keys)
            warning('Participant %d: No aux8_pulses found. Skipping.', i);
            fprintf(fid, 'No aux8_pulses found. Skipped.\n');
            continue;
        end

        auxStim = raw_out(i).stimulus('aux8_pulses');
        auxOnsetsOriginal = auxStim.onset;
        fprintf('Found %d aux pulses (raw).\n', length(auxOnsetsOriginal));
        fprintf(fid, 'Aux pulses detected (raw): %d\n', length(auxOnsetsOriginal));

        % ✅ Remove early outlier pulse if gap is abnormal
        removedOutlier = [];
        if length(auxOnsetsOriginal) > 2
            gaps = diff(auxOnsetsOriginal);
            medianGap = median(gaps);
            if gaps(1) > 2 * medianGap
                removedOutlier = auxOnsetsOriginal(1);
                auxOnsetsOriginal(1) = []; % drop first pulse
                fprintf('Removed early outlier pulse at %.2f s\n', removedOutlier);
                fprintf(fid, 'Removed early outlier pulse at %.2f s\n', removedOutlier);
            end
        end

        % ✅ Filter aux pulses to remove duplicates/noise
        auxOnsetsFiltered = auxOnsetsOriginal([true; diff(auxOnsetsOriginal) > expectedGap/2]);
        fprintf('Filtered aux pulses: %d (from %d)\n', length(auxOnsetsFiltered), length(auxOnsetsOriginal));
        fprintf(fid, 'Filtered aux pulses: %d (from %d)\n', length(auxOnsetsFiltered), length(auxOnsetsOriginal));

        % ✅ Check for stimulus table in base workspace
        stimVarName = sprintf('Participant_%d', i);
        if ~evalin('base', sprintf('exist(''%s'', ''var'')', stimVarName))
            warning('Stimulus table %s not found. Skipping.', stimVarName);
            fprintf(fid, 'Stimulus table missing. Skipped.\n');
            continue;
        end
        stimTable = evalin('base', stimVarName);
        nStim = height(stimTable);

        % ✅ Map aux pulses to trials
        mappedOnsets = auxOnsetsFiltered;
        if length(mappedOnsets) < nStim
            % Fill missing trials using spacing
            extraOnsets = mappedOnsets(end) + (1:(nStim-length(mappedOnsets)))' * trialSpacing;
            mappedOnsets = [mappedOnsets; extraOnsets];
        elseif length(mappedOnsets) > nStim
            % Truncate extras
            mappedOnsets = mappedOnsets(1:nStim);
        end

        fprintf('Final mapped onsets: %d\n', length(mappedOnsets));
        fprintf(fid, 'Final mapped onsets: %d\n', length(mappedOnsets));

        % ✅ Assign stimulus events
        for j = 1:nStim
            
        condName = sprintf('G%.2f_M%.2f', stimTable.GratingContrast(j), stimTable.MaskContrast(j));
        %condName = strrep(strrep(condName, '.', '_'), '-', '_');  % Normalize to underscores

            if ~ismember(condName, raw_out(i).stimulus.keys)
                stimEvent = nirs.design.StimulusEvents();
                stimEvent.name = condName;
                stimEvent.onset = [];
                stimEvent.dur = [];
                stimEvent.amp = [];
                raw_out(i).stimulus(condName) = stimEvent;
            end

            stimEvent = raw_out(i).stimulus(condName);
            stimEvent.onset(end+1) = mappedOnsets(j);
            stimEvent.dur(end+1) = trialDuration;
            stimEvent.amp(end+1) = 1;
            raw_out(i).stimulus(condName) = stimEvent;
        end

        % ✅ QC Plot
        figure('Name', sprintf('Alignment Check - Participant %d', i));
        if ~isempty(removedOutlier)
            plot(removedOutlier, 1.02, 'ks', 'MarkerFaceColor', 'k', 'DisplayName', 'Removed Outlier');
            hold on;
        end
        plot(auxOnsetsOriginal, ones(size(auxOnsetsOriginal)), 'bo', 'DisplayName', 'Raw Aux Pulses');
        hold on;
        plot(auxOnsetsFiltered, 1.05*ones(size(auxOnsetsFiltered)), 'go', 'DisplayName', 'Filtered Aux Pulses');
        plot(mappedOnsets, 1.1*ones(size(mappedOnsets)), 'rx', 'DisplayName', 'Mapped Stim Onsets');
        legend('show');
        xlabel('Time (s)');
        title(sprintf('Participant %d: Aux vs Adjusted Stim Onsets', i));
        hold off;

        fprintf(fid, 'Alignment complete for Participant %d.\n', i);
    end

    fclose(fid);
    fprintf('\nAlignment complete. Log saved to %s\n', logFile);
end