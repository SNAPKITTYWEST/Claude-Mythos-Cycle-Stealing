% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function result = run_experiment(experiment_type)
    % Run a single experiment by type
    % experiment_type: 'baseline', 'random_stealing', 'bounded_stealing',
    %                  'priority_stealing', 'recursive_stealing', 'force_mode',
    %                  'recursive_mythos'

    if nargin < 1
        experiment_type = 'baseline';
    end

    % Load configuration
    config = defaultConfig();
    config.experimentType = experiment_type;
    config.verbose = true;

    % Configure based on experiment type
    switch experiment_type
        case 'baseline'
            config.schedulerType = 'balanced';
            config.stealingPolicy = 'none';
            config.recursionEnabled = false;

        case 'random_stealing'
            config.stealingPolicy = 'random';
            config.stealingProbability = 0.15;

        case 'bounded_stealing'
            config.stealingPolicy = 'bounded';
            config.stealThreshold = 0.2;

        case 'priority_stealing'
            config.stealingPolicy = 'priority';
            config.maxStealersPerRound = 4;

        case 'recursive_stealing'
            config.stealingPolicy = 'recursive';
            config.stealingDepthLimit = 3;

        case 'force_mode'
            config.forceModeEnabled = true;
            config.forceStealingPressure = 5.0;
            config.stealingPolicy = 'random';

        case 'recursive_mythos'
            config.recursionEnabled = true;
            config.mythosEnabled = true;
            config.maxRecursionDepth = 3;

        otherwise
            error('Unknown experiment type: %s', experiment_type);
    end

    % Run experiment
    if config.verbose
        fprintf('Starting experiment: %s\n', experiment_type);
        fprintf('Seed: %d\n', config.seed);
        fprintf('Worker count: %d\n', config.workerCount);
    end

    % Initialize system
    [ledger, queues, workers] = initializeSystem(config);

    % Set deterministic RNG
    rng_state = utils.deterministicSeed(uint64(config.seed));

    % Execute simulation
    [ledger, queues, workers, statistics] = simulateExecution(...
        ledger, queues, workers, config, rng_state);

    % Validate invariants
    [inv_pass, inv_results] = invariant.assertInvariant(ledger, queues, config);

    % Produce results
    result = struct();
    result.experimentId = config.experimentId;
    result.experimentType = experiment_type;
    result.config = config;
    result.ledger = ledger;
    result.queues = queues;
    result.workers = workers;
    result.statistics = statistics;
    result.invariantResults = inv_results;
    result.invariantPass = inv_pass;
    result.completionTime = datetime('now');

    if config.verbose
        fprintf('Experiment complete: %s\n', result.experimentId);
        fprintf('Invariant check: %s\n', char(inv_pass));
        fprintf('Statistics: %d tasks, %.2f mean throughput\n', ...
            statistics.totalTasksCompleted, statistics.meanThroughput);
    end

    % Save results if persistence enabled
    if config.persistenceEnabled
        saveExperimentResult(result, config);
    end

end

function [ledger, queues, workers] = initializeSystem(config)
    % Initialize the complete execution system

    % Create cycle ledger
    ledger = ledger.create(config.totalInitialCycles, config);

    % Allocate cycles to workers
    for i = 1:config.workerCount
        [ledger, ~] = ledger.allocate(uint32(i), config.cyclesPerWorker);
    end

    % Create work queues
    queues = struct();
    queues.type = config.workerQueueType;
    queues.workerQueues = repmat(struct(...
        'tasks', [], 'taskCount', 0), config.workerCount, 1);
    queues.taskLocation = zeros(10000, 1); % Pre-allocate task location map
    queues.nextTaskId = uint64(1);
    queues.totalEnqueued = 0;
    queues.totalDequeued = 0;
    queues.eventCount = 0;
    queues.maxEvents = 1e6;

    % Create workers
    workers = repmat(struct(...
        'workerId', 0, ...
        'cycleCount', 0, ...
        'tasksCompleted', 0, ...
        'tasksFailed', 0, ...
        'totalLatency', 0, ...
        'cyclesConsumed', 0), config.workerCount, 1);

    for i = 1:config.workerCount
        workers(i).workerId = i;
        workers(i).cycleCount = config.cyclesPerWorker;
    end

end

function [ledger, queues, workers, statistics] = simulateExecution(...
    ledger, queues, workers, config, rng_state)
    % Execute the main simulation loop

    statistics = struct();
    statistics.stepCount = 0;
    statistics.totalTasksGenerated = 0;
    statistics.totalTasksCompleted = 0;
    statistics.totalStealOperations = 0;
    statistics.totalCyclesConsumed = 0;
    statistics.workerUtilization = [];

    max_steps = 10000; % Safety limit
    step = 0;

    while step < max_steps && ledger.availableCycles > 0

        step = step + 1;

        % === Scheduling Step ===
        [queues, decisions] = scheduler.schedulerStep(queues, ledger, config);

        % === Task Execution ===
        for i = 1:config.workerCount
            if ledger.workerCycles(i) >= config.taskWorkUnits && ...
               ~scheduler.isEmpty(queues, uint32(i))

                [queues, task, found] = scheduler.dequeue(queues, uint32(i));

                if found
                    % Execute task (consume cycles)
                    cycles_needed = config.taskWorkUnits;
                    [ledger, consumed, ~] = ledger.consume(uint32(i), cycles_needed);

                    if consumed
                        workers(i).tasksCompleted = workers(i).tasksCompleted + 1;
                        workers(i).cyclesConsumed = workers(i).cyclesConsumed + cycles_needed;
                        statistics.totalTasksCompleted = statistics.totalTasksCompleted + 1;
                        statistics.totalCyclesConsumed = statistics.totalCyclesConsumed + cycles_needed;
                    end
                end
            end
        end

        % === Cycle Stealing Step ===
        if strcmp(config.stealingPolicy, 'none') == 0
            [ledger, steal_events] = stealing.stealStep(ledger, config, rng_state);
            statistics.totalStealOperations = statistics.totalStealOperations + length(steal_events);
        end

        % === Task Generation ===
        if step < max_steps / 2 % Only generate tasks in first half
            new_tasks = poissrnd(config.taskGenerationRate);
            for t = 1:new_tasks
                % Assign to least-loaded worker
                [~, dest_worker] = min(ledger.workerCycles);
                task = struct('taskId', queues.nextTaskId, 'priority', 0);
                [queues, ~] = scheduler.enqueue(queues, uint32(dest_worker), task);
                statistics.totalTasksGenerated = statistics.totalTasksGenerated + 1;
            end
        end

        % === Invariant Check ===
        if mod(step, config.invariantCheckFrequency) == 0 && config.validateInvariants
            [inv_pass, ~] = invariant.assertInvariant(ledger, queues, config);
            if ~inv_pass && config.failOnInvariantViolation
                error('Invariant violation at step %d', step);
            end
        end

        statistics.stepCount = step;
    end

    % === Final Statistics ===
    statistics.meanThroughput = statistics.totalTasksCompleted / max(1, statistics.stepCount);
    statistics.meanUtilization = mean(ledger.workerConsumed ./ ledger.workerCycles);

end

function saveExperimentResult(result, config)
    % Save experiment result to file

    if ~exist(config.resultsDir, 'dir')
        mkdir(config.resultsDir);
    end

    filename = fullfile(config.resultsDir, ...
        sprintf('%s_%s.mat', result.experimentId, result.experimentType));

    save(filename, 'result', 'config', '-v7.3');

    if config.verbose
        fprintf('Results saved to: %s\n', filename);
    end

end
