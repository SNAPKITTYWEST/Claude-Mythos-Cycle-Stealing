% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [valid, issues] = validateConfig(config)
    % Validate configuration for consistency and validity

    valid = true;
    issues = {};

    % === Required Fields ===
    required_fields = {
        'experimentId', 'experimentType', 'seed', 'workerCount', ...
        'schedulerType', 'stealingPolicy', 'kernelType', ...
        'totalInitialCycles', 'cyclesPerWorker'
    };

    for i = 1:length(required_fields)
        if ~isfield(config, required_fields{i})
            valid = false;
            issues{end+1} = sprintf('Missing required field: %s', required_fields{i});
        end
    end

    % === Numeric Constraints ===
    if config.workerCount < 1 || config.workerCount > 256
        valid = false;
        issues{end+1} = 'workerCount must be between 1 and 256';
    end

    if config.totalInitialCycles <= 0
        valid = false;
        issues{end+1} = 'totalInitialCycles must be positive';
    end

    if config.cyclesPerWorker <= 0 || config.cyclesPerWorker * config.workerCount > config.totalInitialCycles
        valid = false;
        issues{end+1} = 'cyclesPerWorker configuration exceeds total cycles';
    end

    if config.maxRecursionDepth < 1 || config.maxRecursionDepth > 20
        valid = false;
        issues{end+1} = 'maxRecursionDepth out of range [1,20]';
    end

    % === Policy Validation ===
    valid_schedulers = {'FIFO', 'balanced', 'priority'};
    if ~ismember(config.schedulerType, valid_schedulers)
        valid = false;
        issues{end+1} = sprintf('Invalid schedulerType: %s', config.schedulerType);
    end

    valid_stealing = {'none', 'random', 'bounded', 'priority', 'recursive'};
    if ~ismember(config.stealingPolicy, valid_stealing)
        valid = false;
        issues{end+1} = sprintf('Invalid stealingPolicy: %s', config.stealingPolicy);
    end

    % === Force Mode Validation ===
    if config.forceModeEnabled && config.forceMaxRuntime <= 0
        valid = false;
        issues{end+1} = 'forceMaxRuntime must be positive';
    end

    % === Recursion Validation ===
    if config.recursionEnabled && config.maxTotalNodes < 2
        valid = false;
        issues{end+1} = 'maxTotalNodes must be >= 2 for recursion';
    end

    % === Mythos Validation ===
    if config.mythosEnabled && config.candidateCount < 1
        valid = false;
        issues{end+1} = 'candidateCount must be positive for Mythos';
    end

    % === Statistics Configuration ===
    if config.statisticsEnabled && config.confidenceLevel <= 0 || config.confidenceLevel >= 1
        valid = false;
        issues{end+1} = 'confidenceLevel must be in (0, 1)';
    end

end
