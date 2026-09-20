# Quick Start Guide

Get running in 5 minutes.

## Install

```bash
git clone https://github.com/SNAPKITTYWEST/matlab-cycle-mythos.git
cd matlab-cycle-mythos
```

## Run First Experiment

In MATLAB:

```matlab
addpath(genpath('.'));
result = run_experiment('baseline');
fprintf('Tasks: %d\n', result.statistics.totalTasksCompleted);
```

## Compare Strategies

```matlab
r1 = run_experiment('baseline');
r2 = run_experiment('bounded_stealing');
r3 = run_experiment('priority_stealing');

fprintf('Baseline: %d tasks\n', r1.statistics.totalTasksCompleted);
fprintf('Bounded:  %d tasks (%.0f%% steals)\n', ...
    r2.statistics.totalTasksCompleted, ...
    r2.statistics.totalStealOperations);
fprintf('Priority: %d tasks (%.0f%% steals)\n', ...
    r3.statistics.totalTasksCompleted, ...
    r3.statistics.totalStealOperations);
```

## Run All Experiments

```matlab
results = run_all();
```

## Run Tests

```matlab
run_tests();
```

## Run Benchmarks

```matlab
run_benchmarks();
```

## Run CI Pipeline

```matlab
[pass, results] = run_ci();
fprintf('CI Status: %s\n', char(pass));
```

## Verify Reproducibility

```matlab
config = defaultConfig();
config.seed = 12345;

r1 = run_experiment('baseline');
r2 = run_experiment('baseline');

% Should be identical
assert(r1.statistics.totalTasksCompleted == ...
       r2.statistics.totalTasksCompleted);
fprintf('Reproducibility: VERIFIED\n');
```

## Create Custom Experiment

```matlab
config = defaultConfig();
config.workerCount = 16;
config.stealThreshold = 0.25;
config.seedinPolicy = 'bounded';
config.seed = 54321;

% Use custom config (requires modification to run_experiment)
% result = run_experiment_custom(config);
```

## Check Results

```matlab
result = run_experiment('bounded_stealing');

% Key metrics
tasks = result.statistics.totalTasksCompleted;
cycles = result.statistics.totalCyclesConsumed;
steals = result.statistics.totalStealOperations;

% Invariants
valid = result.invariantPass;

fprintf('Tasks:     %d\n', tasks);
fprintf('Cycles:    %d\n', cycles);
fprintf('Steals:    %d\n', steals);
fprintf('Valid:     %s\n', char(valid));
```

## Export Results

```matlab
result = run_experiment('baseline');

% Save to file
filename = 'my_experiment.mat';
save(filename, 'result');

% Load later
loaded = load(filename);
recovered_result = loaded.result;
```

## Compare Two Strategies

```matlab
baseline_result = run_experiment('baseline');
optimized_result = run_experiment('bounded_stealing');

% Compute speedup
speedup = optimized_result.statistics.totalTasksCompleted / ...
          baseline_result.statistics.totalTasksCompleted;

fprintf('Speedup: %.2f×\n', speedup);
```

## Verify Invariants Pass

```matlab
result = run_experiment('baseline');

if result.invariantPass
    fprintf('✓ All invariants pass\n');
else
    fprintf('✗ Invariant violations detected\n');
    fprintf('Violations: %d\n', result.invariantResults.violationCount);
end
```

## Check Determinism

```matlab
% Run with same seed multiple times
for i = 1:3
    config = defaultConfig();
    config.seed = 42;
    r = run_experiment('baseline');
    fprintf('Run %d: %d tasks\n', i, r.statistics.totalTasksCompleted);
end
% All should print same number
```

## Profile Performance

```matlab
% Measure execution time
tic;
result = run_experiment('baseline');
elapsed = toc;

fprintf('Execution time: %.2f seconds\n', elapsed);
```

## Replay Experiment

```matlab
result = run_experiment('baseline');

% Replay the event log
[ledger_replayed, match, diag] = ledger.replay(...
    result.ledger.events, result.config);

if match
    fprintf('Replay VERIFIED - determinism confirmed\n');
else
    fprintf('Replay MISMATCH - found non-determinism!\n');
end
```

## Statistical Comparison

```matlab
% Run same experiment multiple times
results = {};
for i = 1:5
    config = defaultConfig();
    config.seed = 10000 + i;
    results{i} = run_experiment('bounded_stealing');
end

% Aggregate
agg = statistics.aggregateRuns([results{:}]);

fprintf('Mean tasks: %.0f ± %.0f\n', ...
    agg.tasksCompleted.mean, ...
    agg.tasksCompleted.std);
```

## Learn More

- `docs/user-guide.md` - Complete user guide
- `docs/architecture.md` - System architecture
- `docs/reference.md` - API reference
- `DEVELOPMENT.md` - Development guide

## Common Issues

### "Insufficient cycles" error
- Increase `config.totalInitialCycles`
- Reduce `config.taskWorkUnits`

### Invariant violation
- Run `run_tests()` to isolate issue
- Check configuration with `utils.validateConfig()`

### Slow execution
- Reduce `config.totalInitialCycles`
- Reduce `config.workerCount`
- Disable `config.validateInvariants`

## Next Steps

1. ✓ Run first experiment
2. ✓ Compare strategies
3. ✓ Run test suite
4. ✓ Check invariants
5. Learn system architecture (docs/architecture.md)
6. Explore different workloads (kernels/)
7. Implement custom policies (see DEVELOPMENT.md)
8. Contribute improvements!

## License

BSD-3-Clause OR GPL-1.0 (dual license)

Choose the license that fits your use case.

---

**Framework Version**: 0.1.0  
**Status**: Production Ready  
**Questions?** Check docs/ or open GitHub issue
