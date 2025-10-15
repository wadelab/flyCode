function raw_out = convertAux8Hybrid(raw_in)
% Detects TTL block onsets from aux8 signal.
% Automatically detects polarity and clusters edges into blocks.
% Uses adaptive gap logic: expected trial gap (~21 s), but handles long breaks.

    raw_out = raw_in;
    expectedGap = 6;      % seconds between trials
    adaptiveFactor = 2;    % multiplier for normal gap tolerance
    defaultBlockDur = 0.1; % default block duration

    for i = 1:length(raw_in)
        fprintf('\nProcessing dataset %d...\n', i);

        % --- Ensure aux8 exists ---
        auxKeys = raw_in(i).auxillary.keys;
        if ~any(strcmp(auxKeys, 'aux8')) && length(raw_in(i).auxillary.values) >= 8
            raw_in(i).auxillary('aux8') = raw_in(i).auxillary.values{1,8};
        end

        % --- Extract aux8 data ---
        sig = raw_in(i).auxillary('aux8').data(:);
        t = raw_in(i).time(:);

        % --- Dynamic threshold detection ---
        thr_pos = mean(sig) + 0.5 * std(sig);
        thr_neg = mean(sig) - 0.5 * std(sig);

        sig_pos = sig > thr_pos;
        sig_neg = sig < thr_neg;

        edges_pos = find(diff([0; sig_pos]) == 1);
        edges_neg = find(diff([0; sig_neg]) == 1);

        if length(edges_pos) >= length(edges_neg)
            edges_start = edges_pos;
            polarity = 'positive';
        else
            edges_start = edges_neg;
            polarity = 'negative';
        end

        fprintf('Detected %s polarity for dataset %d.\n', polarity, i);

        % --- Onset detection ---
        onsetTimes = t(edges_start);
        if isempty(onsetTimes)
            warning('No TTL onsets detected.');
            raw_out(i) = raw_in(i);
            continue;
        end

        % --- Adaptive gap clustering ---
        gaps = [Inf; diff(onsetTimes)];
        adaptiveGap = expectedGap * adaptiveFactor; % e.g., 42 s
        blockStartIdx = [1; find(gaps > adaptiveGap)];
        blockOnsets = onsetTimes(blockStartIdx);

        % Assign fixed duration for blocks
        blockDurations = repmat(defaultBlockDur, size(blockOnsets));

        % --- Create stimulus events ---
        stimP = nirs.design.StimulusEvents();
        stimP.name = 'aux8_pulses';
        stimP.onset = blockOnsets(:);
        stimP.dur = blockDurations(:);
        stimP.amp = ones(size(blockOnsets));
        raw_in(i).stimulus(stimP.name) = stimP;

        fprintf('Added %d TTL block onsets.\n', length(blockOnsets));

        raw_out(i) = raw_in(i);
    end
end