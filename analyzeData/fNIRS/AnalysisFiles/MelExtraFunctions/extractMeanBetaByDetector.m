function combinedTable = extractMeanBetaByDetector(SubStats)
% Computes mean beta values per subject and condition, averaged over channels
% connected to detector 1 and detector 2.
%
% INPUT:
%   SubStats - 1 x N array of ChannelStats objects (from NIRS Toolbox)
%
% OUTPUT:
%   combinedTable - Table with mean beta values for Det1 and Det2 combined

% Collect all conditions across subjects
allConds = {};
for s = 1:length(SubStats)
    allConds = [allConds; SubStats(s).variables.cond];
end
conds = unique(allConds);  % Unique condition names
numConds = length(conds);

% Initialize storage
numSubjects = length(SubStats);
combinedData = zeros(numSubjects, numConds * 2);  % Two columns per condition (Det1 & Det2)

for s = 1:numSubjects
    subjVars = SubStats(s).variables;
    subjBeta = SubStats(s).beta;
    
    for c = 1:numConds
        condName = conds{c};
        
        % Find rows for this condition
        condIdx = strcmp(subjVars.cond, condName);
        
        % Detector 1 channels
        det1Idx = condIdx & (subjVars.detector == 1);
        combinedData(s, (c-1)*2 + 1) = mean(subjBeta(det1Idx), 'omitnan');
        
        % Detector 2 channels
        det2Idx = condIdx & (subjVars.detector == 2);
        combinedData(s, (c-1)*2 + 2) = mean(subjBeta(det2Idx), 'omitnan');
    end
end

% Create column names: Det1 first, Det2 second
colNames = cell(1, numConds * 2);
for c = 1:numConds
    colNames{(c-1)*2 + 1} = [conds{c} '_Det1'];
    colNames{(c-1)*2 + 2} = [conds{c} '_Det2'];
end

% Add SubjectID as first column
subjectIDs = arrayfun(@(x) sprintf('Subject_%d', x), 1:numSubjects, 'UniformOutput', false);
combinedTable = array2table(combinedData, 'VariableNames', colNames);
combinedTable = [table(subjectIDs', 'VariableNames', {'SubjectID'}) combinedTable];

% Save to Excel using writecell (works even if writetable fails)
xlswrite('MeanBeta_Combined.xlsx', [combinedTable.Properties.VariableNames; table2cell(combinedTable)]);

end