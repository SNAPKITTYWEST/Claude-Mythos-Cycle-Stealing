% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function results = run_all()
    % Run all experiment types and collect results

    addpath(genpath('./src'));
    addpath(genpath('./config'));

    experiments = {
        'baseline'
        'random_stealing'
        'bounded_stealing'
        'priority_stealing'
        'recursive_stealing'
        'force_mode'
    };

    results = {};

    fprintf('====================================\n');
    fprintf('MATLAB Cycle-Stealing Framework\n');
    fprintf('Running %d experiments\n', length(experiments));
    fprintf('====================================\n\n');

    for i = 1:length(experiments)
        exp_type = experiments{i};
        fprintf('[%d/%d] Running: %s\n', i, length(experiments), exp_type);

        result = run_experiment(exp_type);
        results{i} = result;

        % Print summary
        fprintf('  Invariants: %s\n', char(result.invariantPass));
        fprintf('  Tasks: %d\n', result.statistics.totalTasksCompleted);
        fprintf('  Steals: %d\n', result.statistics.totalStealOperations);
        fprintf('\n');
    end

    fprintf('====================================\n');
    fprintf('All experiments complete\n');
    fprintf('====================================\n');

    % Generate comparison report
    generateComparisonReport(results);

end

function generateComparisonReport(results)
    % Generate a comparison report across all experiments

    fprintf('\n====== COMPARISON REPORT ======\n');
    fprintf('%-20s | %8s | %8s | %8s\n', 'Experiment', 'Tasks', 'Steals', 'Utils');
    fprintf('-' * 60);
    fprintf('\n');

    for i = 1:length(results)
        result = results{i};
        fprintf('%-20s | %8d | %8d | %7.2f%%\n', ...
            result.experimentType, ...
            result.statistics.totalTasksCompleted, ...
            result.statistics.totalStealOperations, ...
            result.statistics.meanUtilization * 100);
    end

    fprintf('\n');

end
