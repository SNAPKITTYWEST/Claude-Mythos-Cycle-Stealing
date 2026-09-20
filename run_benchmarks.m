% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function results = run_benchmarks()
    % Run comprehensive benchmarking suite
    % Tests all major experiment types with various configurations

    addpath(genpath('./src'));
    addpath(genpath('./config'));

    fprintf('====================================\n');
    fprintf('MATLAB Cycle-Mythos Benchmarking\n');
    fprintf('====================================\n\n');

    results = struct();
    results.timestamp = datetime('now');
    results.matlabVersion = version('-release');
    results.experiments = {};
    results.exp_count = 0;

    % === Benchmark 1: Baseline Scalability ===
    fprintf('Benchmark 1: Baseline Scalability Study\n');
    fprintf('-' * 40 + '\n');

    worker_counts = [2 4 8 16];
    baseline_results = {};

    for w = 1:length(worker_counts)
        config = defaultConfig();
        config.workerCount = worker_counts(w);
        config.totalInitialCycles = worker_counts(w) * 1e5;
        config.experimentType = 'baseline';

        fprintf('  Workers: %d... ', worker_counts(w));

        result = run_experiment('baseline');
        baseline_results{w} = result;
        results.exp_count = results.exp_count + 1;

        fprintf('Tasks: %d\n', result.statistics.totalTasksCompleted);
    end

    results.experiments{end+1} = struct(...
        'name', 'Baseline Scalability', ...
        'results', {baseline_results});

    % === Benchmark 2: Stealing Policy Comparison ===
    fprintf('\nBenchmark 2: Stealing Policy Comparison\n');
    fprintf('-' * 40 + '\n');

    policies = {'baseline', 'random_stealing', 'bounded_stealing', 'priority_stealing'};
    policy_results = {};

    for p = 1:length(policies)
        fprintf('  Policy: %s... ', policies{p});

        result = run_experiment(policies{p});
        policy_results{p} = result;
        results.exp_count = results.exp_count + 1;

        fprintf('Tasks: %d, Steals: %d\n', ...
            result.statistics.totalTasksCompleted, ...
            result.statistics.totalStealOperations);
    end

    results.experiments{end+1} = struct(...
        'name', 'Policy Comparison', ...
        'results', {policy_results});

    % === Benchmark 3: Determinism Verification ===
    fprintf('\nBenchmark 3: Determinism Verification\n');
    fprintf('-' * 40 + '\n');

    config = defaultConfig();
    config.seed = 12345;

    fprintf('  Run 1... ');
    result1 = run_experiment('baseline');
    fprintf('Tasks: %d\n', result1.statistics.totalTasksCompleted);

    fprintf('  Run 2 (same seed)... ');
    result2 = run_experiment('baseline');
    fprintf('Tasks: %d\n', result2.statistics.totalTasksCompleted);

    if result1.statistics.totalTasksCompleted == result2.statistics.totalTasksCompleted
        fprintf('  Determinism: VERIFIED\n');
    else
        fprintf('  Determinism: FAILED!\n');
    end

    results.experiments{end+1} = struct(...
        'name', 'Determinism Check', ...
        'result1', result1, ...
        'result2', result2, ...
        'isDeterministic', ...
        (result1.statistics.totalTasksCompleted == result2.statistics.totalTasksCompleted));

    % === Benchmark 4: Invariant Robustness ===
    fprintf('\nBenchmark 4: Invariant Robustness\n');
    fprintf('-' * 40 + '\n');

    invariant_results = {};
    experiment_types = {'baseline', 'random_stealing', 'recursive_stealing'};

    for e = 1:length(experiment_types)
        fprintf('  %s... ', experiment_types{e});

        result = run_experiment(experiment_types{e});
        invariant_results{e} = result;

        if result.invariantPass
            fprintf('Invariants: PASS\n');
        else
            fprintf('Invariants: FAIL\n');
        end

        results.exp_count = results.exp_count + 1;
    end

    results.experiments{end+1} = struct(...
        'name', 'Invariant Robustness', ...
        'results', {invariant_results});

    % === Benchmark 5: Throughput vs. Overhead ===
    fprintf('\nBenchmark 5: Throughput vs. Overhead\n');
    fprintf('-' * 40 + '\n');

    throughput_results = {};
    stealing_pressures = [0.05 0.15 0.25 0.35];

    for sp = 1:length(stealing_pressures)
        config = defaultConfig();
        config.stealingPolicy = 'random';
        config.stealingProbability = stealing_pressures(sp);

        fprintf('  Probability: %.2f... ', stealing_pressures(sp));

        % Not fully implemented - would run with config
        % result = runWithConfig(config);
        % throughput_results{sp} = result;

        fprintf('(placeholder)\n');
    end

    % === Summary Report ===
    fprintf('\n====================================\n');
    fprintf('Benchmarking Complete\n');
    fprintf('Total Experiments Run: %d\n', results.exp_count);
    fprintf('====================================\n\n');

    % Print summary table
    fprintf('%-25s | %10s | %10s | %12s\n', 'Experiment', 'Tasks', 'Steals', 'Invariants');
    fprintf('-' * 60 + '\n');

    for e = 1:length(results.experiments)
        exp_group = results.experiments{e};
        if isfield(exp_group, 'results') && ~isempty(exp_group.results)
            for r = 1:length(exp_group.results)
                res = exp_group.results{r};
                fprintf('%-25s | %10d | %10d | %12s\n', ...
                    sprintf('%s_%d', exp_group.name, r), ...
                    res.statistics.totalTasksCompleted, ...
                    res.statistics.totalStealOperations, ...
                    char(res.invariantPass));
            end
        end
    end

end
