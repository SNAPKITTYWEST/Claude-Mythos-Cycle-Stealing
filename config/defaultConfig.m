% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0
% See LICENSE for dual-license terms

function config = defaultConfig()
    % Create default configuration for cycle-stealing experiments

    config = struct();

    % === Experiment Parameters ===
    config.experimentId = sprintf('exp_%s', char(datetime('now', 'Format', 'yyyyMMdd_HHmmss')));
    config.experimentType = 'baseline'; % 'baseline', 'random_stealing', 'bounded_stealing', 'priority_stealing', 'recursive_stealing', 'force_mode', 'recursive_mythos'
    config.seed = 42;
    config.verbose = true;

    % === Cycle Allocation ===
    config.totalInitialCycles = 1e6; % 1 million cycles
    config.cyclesPerWorker = 1e5; % 100k cycles per worker
    config.stealThreshold = 0.2; % steal when load difference > 20%
    config.maxStealPerOperation = 1000; % max cycles per steal operation

    % === Worker Configuration ===
    config.workerCount = 8;
    config.minWorkers = 1;
    config.maxWorkers = 32;
    config.workerQueueType = 'FIFO'; % 'FIFO', 'Priority'
    config.workerTimeoutCycles = 1000; % cycles before worker considered idle

    % === Scheduler Parameters ===
    config.schedulerType = 'balanced'; % 'FIFO', 'balanced', 'priority'
    config.schedulingPeriod = 100; % check balance every N cycles
    config.rebalanceThreshold = 0.15; % rebalance if variance > 15%
    config.priorityLevels = 4; % number of priority queue levels

    % === Stealing Policy ===
    config.stealingPolicy = 'none'; % 'none', 'random', 'bounded', 'priority', 'recursive'
    config.stealingProbability = 0.1; % probability of stealing per check (random policy)
    config.maxStealersPerRound = 2; % max simultaneous stealing attempts
    config.stealingDepthLimit = 3; % recursive stealing max depth

    % === Computational Kernels ===
    config.kernelType = 'matrix_multiply'; % type of work to perform
    config.kernelSize = 256; % input size for kernels
    config.kernelReps = 10; % repetitions per kernel invocation
    config.operationsPerCycle = 1.0; % flops per simulated cycle
    config.kernelChecksum = true; % verify kernel checksums

    % === Recursion Parameters ===
    config.recursionEnabled = false;
    config.maxRecursionDepth = 5;
    config.maxNodesPerLevel = 4;
    config.maxTotalNodes = 100;
    config.recursionCycleBudget = 1e7; % total cycles for recursive exploration

    % === Mythos Parameters ===
    config.mythosEnabled = false;
    config.candidateCount = 16;
    config.mutationRate = 0.1; % probability of candidate mutation
    config.candidateSearchSpace = 'full'; % 'full', 'limited', 'random'
    config.evaluationReps = 5; % repetitions per candidate
    config.candidateDiversityMetric = 'hamming'; % 'hamming', 'euclidean'

    % === Force Mode Parameters ===
    config.forceModeEnabled = false;
    config.forceStealingPressure = 10.0; % multiplier on stealing pressure
    config.forceSchedulingFrequency = 10.0; % multiplier on scheduling checks
    config.forceRecursionDepth = true; % enable max recursion depth
    config.forceMaxRuntime = 60; % seconds (safety limit)

    % === Execution Parameters ===
    config.maxTasksPerWorker = 1000; % safety limit
    config.taskWorkUnits = 1000; % cycles per task
    config.taskGeneration = 'poisson'; % 'poisson', 'uniform', 'burst'
    config.taskGenerationRate = 10; % tasks per scheduling period
    config.taskFailureRate = 0.0; % fraction of tasks that fail

    % === Persistence ===
    config.persistenceEnabled = true;
    config.resultsDir = './results';
    config.logsDir = './logs';
    config.traceDir = './traces';
    config.saveTraces = true;
    config.saveStatistics = true;
    config.saveFigures = true;

    % === Visualization ===
    config.plotCycles = true;
    config.plotQueues = true;
    config.plotLatency = true;
    config.plotThroughput = true;
    config.plotUtilization = true;
    config.plotStealing = true;
    config.figureFormat = 'png'; % 'png', 'pdf', 'fig'
    config.dpi = 150;

    % === Validation ===
    config.validateInvariants = true;
    config.invariantCheckFrequency = 100; % check every N cycles
    config.detectCycleLeaks = true;
    config.detectDoubleQueue = true;
    config.detectInvalidState = true;

    % === Statistics ===
    config.statisticsEnabled = true;
    config.computePercentiles = true;
    config.percentiles = [10 25 50 75 90 95 99];
    config.computeConfidenceIntervals = true;
    config.confidenceLevel = 0.95;

    % === Replay ===
    config.replayEnabled = true;
    config.replayVerifyExactMatch = true; % require bit-exact reproducibility
    config.replayEventLog = true;

    % === CI/CD ===
    config.ciMode = false;
    config.failOnInvariantViolation = true;
    config.failOnPythonDetection = true;

end
