# User Guide - MATLAB Cycle-Stealing Framework

## Introduction

This guide walks you through using the MATLAB Cycle-Stealing and Recursive Mythos Framework for cycle allocation scheduling research, benchmarking, and optimization.

## Quick Start

### Installation

1. Clone or download the repository
2. Add to MATLAB path:
   ```matlab
   addpath(genpath('/path/to/matlab-cycle-mythos'));
   ```

### First Experiment

Run your first experiment in 3 lines:

```matlab
addpath(genpath('.'));  % Add framework to path
result = run_experiment('baseline');  % Run baseline
fprintf('Tasks completed: %d\n', result.statistics.totalTasksCompleted);
```

### Compare Scheduling Strategies

```matlab
% Run three different scheduling strategies
baseline = run_experiment('baseline');
random = run_experiment('random_stealing');
bounded = run_experiment('bounded_stealing');

% Print results
fprintf('Baseline: %d tasks\n', baseline.statistics.totalTasksCompleted);
fprintf('Random:   %d tasks (steals: %d)\n', ...
    random.statistics.totalTasksCompleted, ...
    random.statistics.totalStealOperations);
fprintf('Bounded:  %d tasks (steals: %d)\n', ...
    bounded.statistics.totalTasksCompleted, ...
    bounded.statistics.totalStealOperations);
```

## Core Concepts

### What is a Cycle?

A cycle is the unit of computational resource. Workers are allocated cycles, which they consume when executing tasks.

- 1 million cycles per worker is typical
- Cycles are finite (conservation law I1)
- Cycles cannot be overspent (non-negativity I2)

### What is Cycle Stealing?

Cycle stealing is load balancing through resource transfer. An underloaded worker can "steal" cycles from an overloaded worker.

**Without stealing**: Workers may complete early while others still have queued tasks

**With stealing**: Cycles redistribute to where they're needed

### Scheduling Policies

1. **Baseline/Balanced** - Fair distribution, no stealing
2. **Random Stealing** - Probabilistic resource transfers
3. **Bounded Stealing** - Threshold-based transfers
4. **Priority Stealing** - Smart worker prioritization
5. **Recursive Stealing** - Hierarchical rebalancing

## Running Experiments

### Basic Experiment Execution

```matlab
% Run a specific experiment type
result = run_experiment('baseline');

% Access results
tasks = result.statistics.totalTasksCompleted;
cycles_used = result.statistics.totalCyclesConsumed;
steals = result.statistics.totalStealOperations;
valid = result.invariantPass;

fprintf('Results:\n');
fprintf('  Tasks:  %d\n', tasks);
fprintf('  Cycles: %d\n', cycles_used);
fprintf('  Steals: %d\n', steals);
fprintf('  Valid:  %s\n', char(valid));
```

### Custom Configuration

```matlab
% Create custom configuration
config = defaultConfig();
config.workerCount = 16;           % More workers
config.stealThreshold = 0.15;      % More aggressive stealing
config.totalInitialCycles = 2e6;   % More cycles
config.seed = 54321;               % Different seed

% Note: Custom configs require manual implementation
% See experiments/runBaseline.m for example
```

### Run All Experiments

```matlab
% Run complete benchmark suite
results = run_all();

% Results is a cell array of all experiment results
for i = 1:length(results)
    r = results{i};
    fprintf('%s: %d tasks\n', r.experimentType, ...
        r.statistics.totalTasksCompleted);
end
```

### Run Benchmarks

```matlab
% Run comprehensive benchmarking
benchmark_results = run_benchmarks();

% Includes:
% - Baseline scalability
% - Policy comparison
% - Determinism verification
% - Invariant robustness
% - Throughput vs overhead analysis
```

## Understanding Results

### Statistics

```matlab
result.statistics.
    totalTasksCompleted        % Tasks finished
    totalCyclesConsumed        % Cycles used
    totalStealOperations       % Stealing events
    meanThroughput             % Tasks/step
    meanUtilization            % Cycles utilization
    workerUtilization          % Per-worker metrics
```

### Invariant Results

```matlab
result.invariantPass           % All invariants pass?
result.invariantResults.       
    I1_pass                    % Cycle conservation
    I2_pass                    % Non-negative balance
    I3_pass                    % Queue integrity
    violationCount             % Total violations
```

### Ledger Details

```matlab
result.ledger.
    totalInitialCycles         % Starting cycles
    allocatedCycles            % Allocated now
    consumedCycles             % Used by tasks
    stolenCycles               % Transferred between workers
    workerCycles               % Per-worker budgets
    events                     % Complete event log
```

## Analysis and Comparison

### Compute Speedup

```matlab
baseline_tasks = baseline_result.statistics.totalTasksCompleted;
optimized_tasks = optimized_result.statistics.totalTasksCompleted;

speedup = optimized_tasks / baseline_tasks;
fprintf('Speedup: %.2f× \n', speedup);
```

### Efficiency Metric

```matlab
% Efficiency = speedup / overhead_ratio
speedup = new_tasks / baseline_tasks;
overhead = (new_steals + 100) / (baseline_steals + 100);
efficiency = speedup / overhead;

fprintf('Efficiency: %.2f (speedup=%.2f, overhead=%.2f)\n', ...
    efficiency, speedup, overhead);
```

### Statistical Comparison

```matlab
% Run experiment multiple times for statistics
results = {};
for i = 1:5
    config = defaultConfig();
    config.seed = 10000 + i;
    results{i} = run_experiment('bounded_stealing');
end

% Aggregate statistics
agg = statistics.aggregateRuns([results{:}]);

fprintf('Mean: %.0f ± %.0f tasks\n', ...
    agg.tasksCompleted.mean, agg.tasksCompleted.std);
fprintf('95%% CI: [%.0f, %.0f]\n', ...
    agg.tasksCompleted.ci95(1), agg.tasksCompleted.ci95(2));
```

## Ensuring Reproducibility

### Deterministic Execution

```matlab
% Same seed → same results
config = defaultConfig();
config.seed = 42;

result1 = run_experiment('baseline');
result2 = run_experiment('baseline');

assert(result1.statistics.totalTasksCompleted == ...
       result2.statistics.totalTasksCompleted);
```

### Replay Verification

```matlab
result = run_experiment('baseline');

% Replay the event log
[ledger_replay, match, diag] = ledger.replay(...
    result.ledger.events, result.config);

% Verify match
assert(match, 'Replay failed to reproduce original');
fprintf('Replay verification: PASS\n');
```

### Version Documentation

```matlab
fprintf('Framework Version: 0.1.0\n');
fprintf('MATLAB: %s\n', version('-release'));
fprintf('Platform: %s\n', computer);
fprintf('Seed: %d\n', result.config.seed);
fprintf('Reproducible: %s\n', char(result.invariantPass));
```

## Visualization

### Plot Queue Depths

```matlab
result = run_experiment('baseline');
queue_state = result.queues;

if isfield(queue_state, 'workerQueues')
    depths = [queue_state.workerQueues.taskCount];
    bar(depths);
    xlabel('Worker ID');
    ylabel('Queue Depth');
    title('Worker Queue Depths');
end
```

### Plot Cycle Usage

```matlab
result = run_experiment('baseline');
ledger = result.ledger;

figure;
consumed = ledger.workerConsumed;
remaining = ledger.workerCycles;

bar([consumed; remaining]');
legend('Consumed', 'Remaining');
xlabel('Worker ID');
ylabel('Cycles');
title('Cycle Usage by Worker');
```

### Plot Stealing Events

```matlab
result = run_experiment('random_stealing');
steals = 0;

for i = 1:length(result.ledger.events)
    if strcmp(result.ledger.events(i).operation, 'steal')
        steals = steals + 1;
    end
end

fprintf('Total stealing events: %d\n', steals);
```

## Testing and Validation

### Run Test Suite

```matlab
% Run all tests
run_tests();

% Or specific test class
run(matlab.unittest.TestLoader().loadTestsFromTestCase(?TestLedger));
```

### Validate Configuration

```matlab
config = defaultConfig();

[valid, issues] = utils.validateConfig(config);
if ~valid
    fprintf('Configuration errors:\n');
    for i = 1:length(issues)
        fprintf('  - %s\n', issues{i});
    end
else
    fprintf('Configuration valid\n');
end
```

### Audit Python Removal

```matlab
% Verify no Python infrastructure
[pass, report] = utils.auditPythonRemoval('.');

fprintf('Python Audit:\n');
fprintf('  Files scanned: %d\n', report.filesScanned);
fprintf('  Python files: %d\n', report.pythonFilesFound);
fprintf('  Forbidden strings: %d\n', report.forbiddenStringsFound);
fprintf('  Status: %s\n', char(pass));
```

## CI/CD and Deployment

### Run CI Pipeline

```matlab
% Complete verification
[all_pass, results] = run_ci();

if all_pass
    fprintf('CI Pipeline: PASS\n');
else
    fprintf('CI Pipeline: FAIL\n');
end
```

### Generate Reports

```matlab
result = run_experiment('baseline');

% Create summary
fprintf('========================================\n');
fprintf('Experiment: %s\n', result.experimentId);
fprintf('Type: %s\n', result.experimentType);
fprintf('========================================\n\n');

fprintf('Results:\n');
fprintf('  Tasks Completed: %d\n', ...
    result.statistics.totalTasksCompleted);
fprintf('  Cycles Consumed: %d\n', ...
    result.statistics.totalCyclesConsumed);
fprintf('  Stealing Events: %d\n', ...
    result.statistics.totalStealOperations);
fprintf('  Invariants Pass: %s\n', char(result.invariantPass));
fprintf('\n');
```

## Troubleshooting

### Low Task Completion

**Symptom**: Fewer tasks than expected

**Causes**:
- Low cycle budget
- Few workers
- Large kernel size

**Fix**:
```matlab
config.totalInitialCycles = config.totalInitialCycles * 2;
% or
config.workerCount = config.workerCount * 2;
% or
config.kernelSize = config.kernelSize / 2;
```

### Invariant Violations

**Symptom**: `invariantPass = false`

**Causes**:
- Bug in scheduler
- Cycle leak
- Queue corruption

**Debug**:
```matlab
[pass, violations, report] = ledger.validate(result.ledger);
for i = 1:length(violations)
    fprintf('%s\n', violations{i});
end
```

### Slow Experiments

**Symptom**: Execution takes too long

**Causes**:
- Too many cycles
- Too many workers
- Too much event logging

**Fix**:
```matlab
config.totalInitialCycles = config.totalInitialCycles / 2;
config.validateInvariants = false; % For quick runs
config.maxEvents = 100000; % Limit event log
```

## Advanced Usage

### Custom Kernels

Implement new kernels in `src/kernels/`:

```matlab
function [result, metadata] = myKernel(n, reps)
    % Your implementation
    % Return cycles estimate and metadata
    result.cycles = estimated_cycles;
end
```

### Custom Stealing Policy

Implement in `src/stealing/`:

```matlab
function [ledger, steal_events] = myPolicy(ledger, config)
    % Your stealing logic
end
```

### Custom Metrics

Add to `src/statistics/`:

```matlab
function metric = myMetric(result)
    % Your metric computation
end
```

## Learning Resources

- `docs/architecture.md` - System design
- `docs/invariants.md` - Machine-checkable invariants
- `docs/design.md` - Design decisions
- `docs/experiments.md` - Experiment methodology
- `docs/reproducibility.md` - Determinism guarantee
- `docs/mythos.md` - Candidate exploration

## Getting Help

1. Check documentation: `docs/` directory
2. Review examples: `tests/` directory
3. Run tests: `run_tests()`
4. Inspect source: `src/` directory

## Citation

If you use this framework in research, cite:

```bibtex
@software{matlab_cycle_mythos_2026,
  title={MATLAB Cycle-Stealing and Recursive Mythos Framework},
  author={SNAPKITTY Research},
  year={2026},
  url={https://github.com/SNAPKITTYWEST/matlab-cycle-mythos}
}
```

## License

Dual-licensed under:
- BSD-3-Clause (permissive)
- GPL-1.0 (copyleft)

Choose the license that fits your use case.

## Support

For issues or questions, open an issue in the repository or contact the maintainers.

---

**Framework Version**: 0.1.0  
**Last Updated**: 2026-09-19  
**Status**: Production Ready
