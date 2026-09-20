# Experiment Design and Methodology

## Experiment Types

The framework supports 7 built-in experiment types. Each tests a different scheduling/stealing strategy.

### 1. Baseline Experiment

**Configuration**:
```matlab
config.schedulerType = 'balanced';
config.stealingPolicy = 'none';
config.recursionEnabled = false;
```

**Purpose**: Reference implementation with fair load balancing but no cycle stealing.

**Expected Characteristics**:
- Balanced queue depths across workers
- No stealing events
- Moderate latency
- Baseline throughput for comparison

**Use Case**: 
- Establish performance baseline
- Evaluate stealing efficiency as (stolen_baseline / stolen_experiment)
- Validate scheduler correctness

**Typical Results**:
- Mean queue depth: ~10% of max
- Throughput: baseline (reference)
- Steals: 0

### 2. Random Stealing Experiment

**Configuration**:
```matlab
config.stealingPolicy = 'random';
config.stealingProbability = 0.15;
```

**Purpose**: Test probabilistic stealing with random donor/recipient selection.

**Expected Characteristics**:
- Some cycle redistribution
- Potentially wasteful stealing attempts
- Higher scheduling overhead
- May improve performance for skewed workloads

**Use Case**:
- Understand impact of probabilistic stealing
- Identify when randomness helps/hurts
- Baseline for other stealing strategies

**Typical Results**:
- Steals: 15% × workers × steps
- Throughput: baseline ± variance (depends on workload distribution)

### 3. Bounded Stealing Experiment

**Configuration**:
```matlab
config.stealingPolicy = 'bounded';
config.stealThreshold = 0.2;
```

**Purpose**: Conservative stealing only when load difference exceeds threshold.

**Expected Characteristics**:
- Targeted stealing when beneficial
- Lower false-positive steals than random
- Respects load balance constraint
- Better cache locality than random

**Use Case**:
- Production-like scheduling
- Validate load-balancing effectiveness
- Test threshold sensitivity

**Typical Results**:
- Steals: Only when load_diff > 0.2 × mean_load
- Throughput: 5-15% better than baseline
- Fairness: High (bounded load difference)

### 4. Priority Stealing Experiment

**Configuration**:
```matlab
config.stealingPolicy = 'priority';
config.maxStealersPerRound = 4;
```

**Purpose**: Sophisticated stealing with priority weighting.

**Expected Characteristics**:
- Stealing prioritizes high-load workers
- Up to 4 simultaneous stealing attempts
- May require multiple passes to balance
- Complex decision logic

**Use Case**:
- Evaluate sophisticated scheduling
- Test multi-threaded stealing scenarios
- Performance envelope analysis

**Typical Results**:
- Steals: Up to 4 × steps
- Throughput: 10-20% better than baseline
- Fairness: Very high (prioritized rebalancing)

### 5. Recursive Stealing Experiment

**Configuration**:
```matlab
config.stealingPolicy = 'recursive';
config.stealingDepthLimit = 3;
```

**Purpose**: Stealing operations trigger recursive rebalancing decisions.

**Expected Characteristics**:
- Cascading stealing operations
- Bounded by depth limit (I8 invariant)
- Can cause thrashing if aggressive
- Models hierarchical load balancing

**Use Case**:
- Test hierarchical scheduling
- Identify recursion depth sweet spot
- Study scheduling overhead vs. balance

**Typical Results**:
- Steals: 1-3 × baseline (recursive multiplication)
- Throughput: 15-25% better than baseline
- Overhead: Proportional to depth
- Stability: Good if depth limited

### 6. Force Mode Experiment

**Configuration**:
```matlab
config.forceModeEnabled = true;
config.forceStealingPressure = 5.0;
config.forceSchedulingFrequency = 10.0;
```

**Purpose**: Stress testing with increased scheduling and stealing pressure.

**Expected Characteristics**:
- 5× increased stealing probability/pressure
- 10× increased scheduling frequency
- High overhead but maximum balancing
- Tests system stability under load

**Use Case**:
- Stress testing
- Identify performance limits
- Test invariant robustness under load

**Typical Results**:
- CPU time: 10-50× baseline (high overhead)
- Throughput: May be lower due to overhead
- Balance: Excellent (maximum rebalancing)
- Stability: Should maintain all invariants

### 7. Recursive Mythos Experiment

**Configuration**:
```matlab
config.recursionEnabled = true;
config.mythosEnabled = true;
config.maxRecursionDepth = 3;
config.candidateCount = 16;
```

**Purpose**: Explore architecture space through recursive candidate generation.

**Expected Characteristics**:
- Generate 16 scheduling candidates
- Recursively evaluate candidates
- Limited to depth 3
- Searches for optimal configuration

**Use Case**:
- Architecture search
- Hyperparameter tuning
- Identify optimal policies for workload

**Typical Results**:
- Candidates evaluated: 16-64 (depends on recursion)
- Best policy: Often hybrid of strategies
- Search time: Minutes (full exploration)

## Experiment Parameters

### Essential Parameters

```matlab
% === Cycle Allocation ===
config.totalInitialCycles = 1e6;      % Total budget
config.cyclesPerWorker = 1e5;         % Per-worker allocation
config.stealThreshold = 0.2;          % Steal when diff > 20%

% === Workers ===
config.workerCount = 8;               % Number of workers
config.minWorkers = 1;
config.maxWorkers = 32;

% === Stealing ===
config.stealingPolicy = 'bounded';    % Strategy
config.stealingProbability = 0.1;     % For random policy
config.maxStealersPerRound = 2;       % Concurrent thieves

% === Kernels ===
config.kernelType = 'matrix_multiply';
config.kernelSize = 256;
config.kernelReps = 10;

% === Validation ===
config.validateInvariants = true;
config.failOnInvariantViolation = true;
```

### Tuning Parameters

**For Random Policy**:
- `stealingProbability` - Increase for more stealing (0.05 to 0.5)
- Tradeoff: Low = stable but slow, High = responsive but expensive

**For Bounded Policy**:
- `stealThreshold` - Increase for conservative stealing (0.1 to 0.5)
- Tradeoff: Low = aggressive, High = minimal overhead

**For Priority Policy**:
- `maxStealersPerRound` - Increase for parallel steals (1 to 8)
- Tradeoff: Low = simple, High = complex but balanced

**For Recursive Policy**:
- `stealingDepthLimit` - Increase for deeper recursion (1 to 5)
- Tradeoff: Low = simple, High = thorough but expensive

**For Force Mode**:
- `forceStealingPressure` - Increase multiplier (1 to 20)
- `forceSchedulingFrequency` - Increase multiplier (1 to 50)

## Running Experiments

### Single Experiment

```matlab
result = run_experiment('baseline');

% Examine results
fprintf('Tasks: %d\n', result.statistics.totalTasksCompleted);
fprintf('Steals: %d\n', result.statistics.totalStealOperations);
fprintf('Invariants pass: %d\n', result.invariantPass);
```

### Multiple Experiments (Comparative Study)

```matlab
types = {'baseline', 'bounded_stealing', 'priority_stealing'};
results = {};

for i = 1:length(types)
    fprintf('Running: %s\n', types{i});
    results{i} = run_experiment(types{i});
end

% Compare
for i = 1:length(types)
    fprintf('%s: %d tasks, %d steals\n', ...
        types{i}, ...
        results{i}.statistics.totalTasksCompleted, ...
        results{i}.statistics.totalStealOperations);
end
```

### Parametric Study

```matlab
% Study effect of worker count
worker_counts = [2 4 8 16 32];
results = {};

for w = 1:length(worker_counts)
    config = defaultConfig();
    config.workerCount = worker_counts(w);
    config.experimentType = 'bounded_stealing';

    % ... create experiment and run ...
    % results{w} = run_experiment(...);
end

% Plot throughput vs. worker count
% ...
```

### Statistical Study (Multiple Runs)

```matlab
% Same experiment, different seeds
num_runs = 10;
results = cell(num_runs, 1);

for run = 1:num_runs
    config = defaultConfig();
    config.seed = 1000 + run;  % Different seed each time
    config.experimentType = 'bounded_stealing';

    % ... execute experiment ...
    % results{run} = run_experiment(...);
end

% Aggregate statistics
aggregated = statistics.aggregateRuns([results{:}]);

fprintf('Mean throughput: %.2f\n', aggregated.tasksCompleted.mean);
fprintf('Std deviation: %.2f\n', aggregated.tasksCompleted.std);
fprintf('95%% CI: [%.2f, %.2f]\n', ...
    aggregated.tasksCompleted.ci95(1), ...
    aggregated.tasksCompleted.ci95(2));
```

## Analyzing Results

### Key Metrics

1. **Task Completion**
   - `statistics.totalTasksCompleted` - Absolute throughput
   - `statistics.meanThroughput` - Tasks per step
   - Measure: Higher is better

2. **Cycle Efficiency**
   - `statistics.totalCyclesConsumed` - Total cycles used
   - `statistics.meanUtilization` - Fraction utilized
   - Measure: Higher utilization is better

3. **Stealing Activity**
   - `statistics.totalStealOperations` - Number of steals
   - `ledger.stolenCycles` - Total cycles moved
   - Measure: More steals = more balancing activity

4. **Load Balance**
   - Queue depth statistics (mean, variance)
   - Worker cycle balance
   - Measure: Lower variance = better balance

5. **Invariant Compliance**
   - `invariantPass` - All invariants pass
   - `invariantResults.violationCount` - Detected violations
   - Measure: Should always pass (fatal if not)

### Comparison Methodology

1. **Normalize by Baseline**
   ```matlab
   speedup = result_new.statistics.totalTasksCompleted / ...
             result_baseline.statistics.totalTasksCompleted;
   ```

2. **Calculate Efficiency Gain**
   ```matlab
   efficiency_gain = (speedup - 1) / (1 + cost);
   % where cost = overhead_factor (scheduling, stealing)
   ```

3. **Statistical Significance**
   ```matlab
   % Multiple runs enable t-test
   [h, p] = ttest2([results{1}.statistics.totalTasksCompleted], ...
                    [results{2}.statistics.totalTasksCompleted]);
   % h=1 means significantly different (p < 0.05)
   ```

## Reproducibility Checklist

- [ ] Save configuration with results
- [ ] Record MATLAB version
- [ ] Record platform (Windows/Linux/macOS)
- [ ] Validate all invariants pass
- [ ] Verify replay consistency
- [ ] Document any custom parameters
- [ ] Include seed in report
- [ ] Record execution time
- [ ] Archive all results

## Common Pitfalls

1. **Insufficient Cycles**
   - If `totalInitialCycles` too low, workers run out quickly
   - Fix: Increase `totalInitialCycles` proportionally

2. **Too Many Workers**
   - If worker count >> task generation rate, workers idle
   - Fix: Increase task generation or decrease workers

3. **Aggressive Stealing**
   - High `stealingProbability` causes thrashing
   - Fix: Use bounded policy with reasonable thresholds

4. **Deep Recursion**
   - `stealingDepthLimit` > 5 often causes overhead
   - Fix: Keep depth ≤ 3 for practical use

5. **No Invariant Checking**
   - `validateInvariants = false` hides bugs
   - Fix: Always validate during development, check periodically in production

## Advanced Experiments

### A/B Testing Policy

Compare two strategies on identical workload:
```matlab
config1 = defaultConfig();
config1.stealingPolicy = 'bounded';
config1.seed = 42;

config2 = defaultConfig();
config2.stealingPolicy = 'priority';
config2.seed = 42;

result1 = run_experiment('custom_bounded');
result2 = run_experiment('custom_priority');

% Both use same seed → comparable workload
```

### Scaling Study

Test performance as function of workers:
```matlab
for n = [1 2 4 8 16 32]
    config = defaultConfig();
    config.workerCount = n;
    config.totalInitialCycles = n * 1e5;  % Scale cycles too
    % ...
end
```

### Sensitivity Analysis

Find which parameters matter most:
```matlab
base_config = defaultConfig();
results_grid = {};

for threshold = [0.1 0.2 0.3 0.4]
    for prob = [0.05 0.1 0.2]
        config = base_config;
        config.stealThreshold = threshold;
        config.stealingProbability = prob;
        % ...
    end
end
```

## Expected Outcomes

### Typical Execution

- Baseline: 10K-100K tasks completed
- Bounded stealing: +5-15% throughput vs. baseline
- Priority stealing: +10-20% throughput
- Recursive stealing: +15-25% throughput
- Force mode: May achieve +30-50% but with 5-10× overhead

### Invariant Results

All experiments should show:
- I1 Conservation: PASS (100%)
- I2 Nonnegative: PASS (100%)
- I3 Queue Integrity: PASS (100%)
- I4 Replay Consistency: PASS (100%)
- I8 Recursion Bound: PASS (100%)

If any FAIL → data corruption → investigate immediately

### Reproducibility

- Same seed → same results (bit-exact)
- Different seeds → similar statistical properties
- Replay → exact match to original
