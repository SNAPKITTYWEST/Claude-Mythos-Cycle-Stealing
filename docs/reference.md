# API Reference

## Top-Level Functions

### `run_experiment(experiment_type)`

Execute a single experiment.

**Syntax**:
```matlab
result = run_experiment('baseline');
result = run_experiment('random_stealing');
result = run_experiment('bounded_stealing');
result = run_experiment('priority_stealing');
result = run_experiment('recursive_stealing');
result = run_experiment('force_mode');
result = run_experiment('recursive_mythos');
```

**Input**:
- `experiment_type` - String specifying experiment type

**Output**:
- `result` - Result structure containing all metrics and state

**Result Fields**:
```matlab
result.experimentId              % Unique experiment ID
result.experimentType            % Type of experiment
result.config                    % Configuration used
result.ledger                    % Cycle ledger final state
result.queues                    % Queue state
result.workers                   % Worker states
result.statistics                % Performance statistics
result.invariantResults          % Invariant validation
result.invariantPass             % All invariants pass?
result.completionTime            % Execution time
```

### `run_all()`

Run all experiment types.

**Syntax**:
```matlab
results = run_all();
```

**Output**:
- `results` - Cell array of result structures

### `run_tests()`

Execute complete test suite.

**Syntax**:
```matlab
results = run_tests();
```

**Output**:
- `results` - Test results

### `run_benchmarks()`

Run comprehensive benchmarking suite.

**Syntax**:
```matlab
benchmark_results = run_benchmarks();
```

**Output**:
- `benchmark_results` - Benchmarking results

### `run_ci()`

Execute CI/CD pipeline.

**Syntax**:
```matlab
[all_pass, results] = run_ci();
```

**Outputs**:
- `all_pass` - Logical indicating overall pass/fail
- `results` - Structure with all audit results

## Configuration

### `defaultConfig()`

Get default configuration.

**Syntax**:
```matlab
config = defaultConfig();
```

**Output**:
- `config` - Default configuration structure

**Key Fields**:
```matlab
config.totalInitialCycles       % Total cycles budget
config.cyclesPerWorker          % Per-worker allocation
config.workerCount              % Number of workers
config.schedulerType            % Scheduler policy
config.stealingPolicy           % Stealing policy
config.kernelType               % Kernel type
config.seed                     % RNG seed
config.validateInvariants       % Check invariants?
config.failOnInvariantViolation  % Halt on violation?
```

## Cycle Ledger

### `ledger.create()`

Create new ledger.

**Syntax**:
```matlab
ledger = ledger.create(totalCycles, config);
```

### `ledger.allocate()`

Allocate cycles to worker.

**Syntax**:
```matlab
[ledger, eventId] = ledger.allocate(ledger, workerId, cycles);
```

### `ledger.consume()`

Consume cycles from worker.

**Syntax**:
```matlab
[ledger, success, eventId] = ledger.consume(ledger, workerId, cycles);
```

### `ledger.transfer()`

Transfer cycles (stealing).

**Syntax**:
```matlab
[ledger, success, eventId] = ledger.transfer(ledger, donor, thief, cycles);
```

### `ledger.returnCycles()`

Return unused cycles.

**Syntax**:
```matlab
[ledger, eventId] = ledger.returnCycles(ledger, workerId, cycles);
```

### `ledger.snapshot()`

Get ledger snapshot.

**Syntax**:
```matlab
snap = ledger.snapshot(ledger);
```

### `ledger.validate()`

Validate ledger invariants.

**Syntax**:
```matlab
[isValid, violations, report] = ledger.validate(ledger);
```

### `ledger.replay()`

Replay event sequence.

**Syntax**:
```matlab
[ledger_replayed, match, diag] = ledger.replay(events, config);
```

## Scheduler

### `scheduler.enqueue()`

Add task to queue.

**Syntax**:
```matlab
[queues, taskId] = scheduler.enqueue(queues, workerId, task);
```

### `scheduler.dequeue()`

Remove task from queue.

**Syntax**:
```matlab
[queues, task, found] = scheduler.dequeue(queues, workerId);
```

### `scheduler.peek()`

View next task.

**Syntax**:
```matlab
[task, found] = scheduler.peek(queues, workerId);
```

### `scheduler.isEmpty()`

Check if queue empty.

**Syntax**:
```matlab
empty = scheduler.isEmpty(queues, workerId);
```

### `scheduler.getQueueSize()`

Get queue depth.

**Syntax**:
```matlab
size = scheduler.getQueueSize(queues, workerId);
```

### `scheduler.queueState()`

Get queue snapshot.

**Syntax**:
```matlab
state = scheduler.queueState(queues);
```

### `scheduler.balance()`

Rebalance queues.

**Syntax**:
```matlab
[queues, moveCount] = scheduler.balance(queues, threshold);
```

### `scheduler.schedulerStep()`

Execute scheduling step.

**Syntax**:
```matlab
[queues, decisions] = scheduler.schedulerStep(queues, ledger, config);
```

## Stealing Policies

### `stealing.randomPolicy()`

Random stealing.

**Syntax**:
```matlab
[ledger, steal_events] = stealing.randomPolicy(ledger, config, rng_state);
```

### `stealing.boundedPolicy()`

Threshold-based stealing.

**Syntax**:
```matlab
[ledger, steal_events] = stealing.boundedPolicy(ledger, config);
```

### `stealing.priorityPolicy()`

Priority-weighted stealing.

**Syntax**:
```matlab
[ledger, steal_events] = stealing.priorityPolicy(ledger, config);
```

### `stealing.recursivePolicy()`

Recursive stealing.

**Syntax**:
```matlab
[ledger, steal_events] = stealing.recursivePolicy(ledger, config, depth);
```

### `stealing.policyFactory()`

Dispatch to selected policy.

**Syntax**:
```matlab
[ledger, steal_events] = stealing.policyFactory(ledger, config, rng_state);
```

### `stealing.stealStep()`

Execute stealing step.

**Syntax**:
```matlab
[ledger, steal_events] = stealing.stealStep(ledger, config, rng_state);
```

## Computational Kernels

### `kernels.matrixMultiply()`

Matrix multiplication.

**Syntax**:
```matlab
[result, metadata] = kernels.matrixMultiply(n, reps);
```

### `kernels.fftKernel()`

FFT computation.

**Syntax**:
```matlab
[result, metadata] = kernels.fftKernel(n, reps);
```

### `kernels.convolution()`

Convolution operation.

**Syntax**:
```matlab
[result, metadata] = kernels.convolution(n, kernel_size, reps);
```

### `kernels.sortKernel()`

Array sorting.

**Syntax**:
```matlab
[result, metadata] = kernels.sortKernel(n, reps);
```

### `kernels.reduction()`

Reduction operation.

**Syntax**:
```matlab
[result, metadata] = kernels.reduction(n, reps);
```

### `kernels.benchmarkKernel()`

Unified kernel interface.

**Syntax**:
```matlab
[result, metadata] = kernels.benchmarkKernel(type, size, reps);
```

## Invariants

### `invariant.cycleConservation()`

Test I1.

**Syntax**:
```matlab
[pass, diagnostic] = invariant.cycleConservation(ledger);
```

### `invariant.nonnegativeBalance()`

Test I2.

**Syntax**:
```matlab
[pass, diagnostic] = invariant.nonnegativeBalance(ledger);
```

### `invariant.queueIntegrity()`

Test I3.

**Syntax**:
```matlab
[pass, diagnostic] = invariant.queueIntegrity(queues);
```

### `invariant.replayConsistency()`

Test I4.

**Syntax**:
```matlab
[pass, diagnostic] = invariant.replayConsistency(snap1, snap2);
```

### `invariant.latencyBound()`

Test I6.

**Syntax**:
```matlab
[pass, diagnostic] = invariant.latencyBound(ledger, workers, config);
```

### `invariant.recursionBound()`

Test I8.

**Syntax**:
```matlab
[pass, diagnostic] = invariant.recursionBound(tree, config);
```

### `invariant.assertInvariant()`

Check all invariants.

**Syntax**:
```matlab
[all_pass, results] = invariant.assertInvariant(ledger, queues, config);
```

## Utilities

### `utils.deterministicSeed()`

Set deterministic RNG.

**Syntax**:
```matlab
rng_state = utils.deterministicSeed(seed);
```

### `utils.validateConfig()`

Validate configuration.

**Syntax**:
```matlab
[valid, issues] = utils.validateConfig(config);
```

### `utils.auditPythonRemoval()`

Audit for Python infrastructure.

**Syntax**:
```matlab
[pass, report] = utils.auditPythonRemoval(repository_root);
```

### `utils.hashState()`

Hash state for reproducibility.

**Syntax**:
```matlab
hash = utils.hashState(state);
```

## Statistics

### `statistics.aggregateRuns()`

Aggregate multiple runs.

**Syntax**:
```matlab
aggregated = statistics.aggregateRuns(results_array);
```

## Mythos Engine

### `mythos.generateCandidates()`

Generate candidates.

**Syntax**:
```matlab
candidates = mythos.generateCandidates(config, seed, count);
```

### `mythos.evaluateCandidate()`

Evaluate candidate.

**Syntax**:
```matlab
[score, details] = mythos.evaluateCandidate(candidate, reps);
```

## Recursion

### `recursion.createNode()`

Create tree node.

**Syntax**:
```matlab
node = recursion.createNode(nodeId, parentId, depth, config, candidate);
```

### `recursion.expandNode()`

Expand tree node.

**Syntax**:
```matlab
[node, children] = recursion.expandNode(node, config, base_config);
```

## Common Patterns

### Compare Two Strategies

```matlab
r1 = run_experiment('baseline');
r2 = run_experiment('bounded_stealing');

speedup = r2.statistics.totalTasksCompleted / ...
          r1.statistics.totalTasksCompleted;
fprintf('Speedup: %.2f×\n', speedup);
```

### Statistical Analysis

```matlab
results = {};
for i = 1:10
    config = defaultConfig();
    config.seed = 10000 + i;
    results{i} = run_experiment('bounded_stealing');
end

agg = statistics.aggregateRuns([results{:}]);
fprintf('Mean: %.0f ± %.0f\n', agg.tasksCompleted.mean, agg.tasksCompleted.std);
```

### Reproducibility Check

```matlab
config = defaultConfig();
config.seed = 42;

r1 = run_experiment('baseline');
r2 = run_experiment('baseline');

assert(r1.statistics.totalTasksCompleted == r2.statistics.totalTasksCompleted);
fprintf('Reproducibility: PASS\n');
```

## Error Handling

### Check Invariants

```matlab
result = run_experiment('baseline');

if ~result.invariantPass
    fprintf('Invariant violation detected!\n');
    fprintf('Violations: %d\n', result.invariantResults.violationCount);
end
```

### Validate Configuration

```matlab
config = defaultConfig();
[valid, issues] = utils.validateConfig(config);

if ~valid
    for i = 1:length(issues)
        fprintf('Error: %s\n', issues{i});
    end
end
```

## Performance Notes

- Single experiment: 10-60 seconds (typical)
- Baseline: 30-50 sec
- With stealing: 40-70 sec
- Force mode: 5-10 minutes
- Complete benchmark: 30-60 minutes
- Test suite: 5-10 minutes

## Memory Requirements

- Ledger: ~1-10 MB (depends on event log size)
- Result: ~5-50 MB (depends on event count)
- Multiple runs: 100+ MB
- Complete archive: 1+ GB

## Troubleshooting

### "Insufficient cycles" error
- Increase `config.totalInitialCycles`
- Reduce `config.taskWorkUnits`

### "Invariant violation" error
- Check configuration validity
- Review implementation for bugs
- Run tests to isolate issue

### Slow performance
- Reduce event log size
- Disable invariant checking during runs
- Use smaller kernel sizes

---

This reference covers the public API. See source files for internal function details.
