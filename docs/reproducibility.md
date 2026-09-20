# Reproducibility and Determinism

This document describes how the framework guarantees bit-exact reproducibility of experiments.

## Determinism Principles

### 1. Deterministic RNG

The framework uses seeded MT19937 random number generator:

```matlab
rng_state = utils.deterministicSeed(uint64(seed));
```

**Property**: For any given seed value, the RNG produces the exact same sequence.

**Usage**: 
- Random stealing policy uses deterministic RNG for donor selection
- Task generation uses deterministic RNG for work generation rates
- All other components use deterministic algorithms

### 2. Explicit State Logging

Every state change is logged as an event:

```matlab
event = struct();
event.eventId = ledger.eventCount + 1;
event.timestamp = datetime('now');
event.operation = 'allocate';  % or 'consume', 'steal', 'return'
event.workerId = workerId;
event.cycles = cycles;
event.previousBalance = previousBalance;
event.newBalance = newBalance;
```

**Property**: Complete event log enables perfect replay.

### 3. Event Sequence Ordering

Events are ordered by:
1. Execution step (deterministic algorithm progression)
2. Worker ID (deterministic tie-breaking)
3. Event ID (sequential assignment)

**Property**: Same seed + config → same event sequence

### 4. Integer-Only Accounting

All cycle accounting uses integers, never floating-point:

```matlab
ledger.workerCycles = zeros(config.workerCount, 1, 'uint64');
```

**Property**: No accumulated rounding errors

### 5. No Timestamp Dependencies

While events are timestamped, the computation is NOT timestamp-dependent:

```matlab
event.timestamp = datetime('now');  % For logging only
% Determinism verified by event sequence, NOT timestamps
```

**Property**: Clock skew, system load variations don't affect results

## Reproducibility Workflow

### Step 1: Record Original Run

```matlab
config = defaultConfig();
config.seed = 42;
config.experimentType = 'baseline';

% Run experiment
result1 = run_experiment('baseline');

% Save configuration
original_config = result1.config;
original_ledger = result1.ledger;
```

### Step 2: Reproduce Exact Experiment

```matlab
% Create identical configuration
config2 = original_config;
config2.experimentId = 'reproduction_' + string(datetime('now'));

% Run with same seed
result2 = run_experiment('baseline');

% Compare final states
snap1 = ledger.snapshot(result1.ledger);
snap2 = ledger.snapshot(result2.ledger);

[match, diag] = invariant.replayConsistency(snap1, snap2);
assert(match, 'Reproduction failed');
```

### Step 3: Verify Invariants

```matlab
[pass1, report1] = ledger.validate(result1.ledger);
[pass2, report2] = ledger.validate(result2.ledger);

assert(pass1 && pass2, 'Invariant violation');
```

## Replay Verification

The framework can replay any stored experiment to verify determinism:

```matlab
% Loaded from disk
events = result.ledger.events;
config = result.config;

% Replay events
[ledger_replayed, match_status, diagnostics] = ledger.replay(events, config);

% Verify state matches
assert(ledger_replayed.consumedCycles == result.ledger.consumedCycles);
assert(all(ledger_replayed.workerCycles == result.ledger.workerCycles));
```

**Guarantee**: If replay succeeds, the original recording was deterministic.

## Determinism Limits

### What IS Deterministic
- Cycle allocation and consumption (deterministic math)
- Worker cycle stealing (deterministic RNG)
- Task scheduling (deterministic algorithms)
- Task execution (no variability)
- Invariant checking (deterministic logic)

### What is NOT Deterministic  
- Wall-clock execution time (dependent on system load)
- Elapsed wall-clock time measurements (dependent on CPU scheduling)
- File system timing (variable)

**Note**: The system is deterministic in the *logical* sense (same inputs → same logical steps), even though wall-clock time varies.

## Testing Determinism

The test suite includes determinism verification:

```matlab
classdef TestDeterminism < matlab.unittest.TestCase

    methods(Test)

        function testBaselineDeterminism(testCase)
            % Same config → same results
            config = defaultConfig();
            config.seed = 123;

            result1 = run_experiment('baseline');
            result2 = run_experiment('baseline');

            testCase.verifyEqual(result1.statistics.totalTasksCompleted, ...
                result2.statistics.totalTasksCompleted);
            testCase.verifyEqual(result1.ledger.consumedCycles, ...
                result2.ledger.consumedCycles);
        end

        function testReplayDeterminism(testCase)
            % Replay identical events → identical state
            config = defaultConfig();
            result = run_experiment('baseline');

            [ledger_replayed, match, diag] = ledger.replay(...
                result.ledger.events, config);

            testCase.verifyTrue(match);
            testCase.verifyEqual(ledger_replayed.consumedCycles, ...
                result.ledger.consumedCycles);
        end

    end

end
```

## CI/CD Reproducibility

The CI pipeline includes reproducibility checks:

```matlab
[all_pass, results] = run_ci();
```

This verifies:
1. Deterministic RNG seeding works correctly
2. Event replay produces identical results
3. Configuration validation is consistent
4. All invariants are reproducibly maintained

## Storage and Recall

Experiments can be stored and recalled for later analysis:

```matlab
% Save
result = run_experiment('baseline');
save('baseline_exp.mat', 'result', 'config');

% Later: Reload and verify
load('baseline_exp.mat');
snap_original = ledger.snapshot(result.ledger);

% Replay to verify integrity
[ledger_replayed, match, diag] = ledger.replay(result.ledger.events, config);
snap_replayed = ledger.snapshot(ledger_replayed);

[match_invariant, diag_invariant] = invariant.replayConsistency(...
    snap_original, snap_replayed);
assert(match_invariant);
```

## Multi-Run Reproducibility

Comparing multiple experiment types while maintaining reproducibility:

```matlab
% Run with identical parameters across types
config = defaultConfig();
config.seed = 42;

for exp_type = {'baseline', 'random_stealing', 'bounded_stealing'}
    config.experimentType = exp_type{1};
    config.stealingPolicy = selectPolicy(exp_type);
    
    result = run_experiment(exp_type);
    % Each run is independently deterministic
end
```

## Reproducibility Report

Every experiment can generate a reproducibility certificate:

```matlab
function cert = reproducibilityCertificate(result)
    cert = struct();
    cert.experimentId = result.experimentId;
    cert.seed = result.config.seed;
    cert.configHash = utils.hashState(result.config);
    cert.finalStateHash = utils.hashState(struct(...
        'consumed', result.ledger.consumedCycles, ...
        'workers', result.ledger.workerCycles, ...
        'events', result.ledger.eventCount));
    cert.invariantsPass = result.invariantPass;
    cert.timestamp = datetime('now');
    cert.matlabVersion = version('-release');
end
```

This certificate enables later verification that reproduction was successful.

## Guarantee Statement

**Reproducibility Guarantee**: 

Any experiment recorded in the framework with:
- Identical configuration (same seed, parameters)
- Identical MATLAB version
- Identical platform (Windows/Linux/macOS)

Will produce:
- Identical event sequence
- Identical final ledger state
- Identical cycle accounting
- Identical invariant results

Verifiable through replay verification and checksum comparison.

## Troubleshooting Non-Reproducibility

If reproduction fails:

1. **Check Seed Match**
   ```matlab
   assert(result1.config.seed == result2.config.seed);
   ```

2. **Check Configuration Match**
   ```matlab
   [config_valid, issues] = utils.validateConfig(result1.config);
   assert(config_valid);
   ```

3. **Check Invariants**
   ```matlab
   [pass1, report1] = ledger.validate(result1.ledger);
   [pass2, report2] = ledger.validate(result2.ledger);
   assert(pass1 && pass2);
   ```

4. **Check Event Replay**
   ```matlab
   [ledger_replayed, match, diag] = ledger.replay(result.ledger.events, config);
   if ~match
       fprintf('Replay mismatch: %s\n', diag.message);
   end
   ```

5. **Compare Event Sequences**
   ```matlab
   if length(result1.ledger.events) ~= length(result2.ledger.events)
       error('Event count mismatch: %d vs %d', ...
           length(result1.ledger.events), length(result2.ledger.events));
   end
   ```

If all checks pass but results differ, contact the maintainers with:
- MATLAB version
- Platform (Windows/Linux/macOS)
- Configuration
- Results from all checks above
