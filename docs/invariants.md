# Machine-Checkable Invariants

This document specifies the 10 core invariants that govern the entire system. All invariants are machine-checkable and actively validated throughout execution.

## I1: Cycle Conservation

**Statement**: `totalInitialCycles == allocatedCycles + availableCycles`

**Meaning**: No cycles are created or destroyed. Every cycle either:
- Has been allocated to a worker, or
- Remains in the available pool

**Rationale**: Cycles are the fundamental unit of resource accounting. Cycle creation would violate conservation laws and mask resource leaks. Cycle destruction would hide resource loss.

**Implementation**: `src/invariant/cycleConservation.m`

**Check Frequency**: Every scheduling decision, at least once per 100 cycles

**Violation Recovery**: Fatal error - cannot continue

```matlab
[pass, diag] = invariant.cycleConservation(ledger);
if ~pass
    fprintf('FATAL: %s\n', diag.message);
end
```

## I2: Nonnegative Balances

**Statement**: `∀ worker i: workerCycles[i] >= 0`

**Meaning**: No worker's cycle balance can go negative. Workers cannot overspend their budget.

**Rationale**: Negative cycles would represent debt or illegal state. The system cannot guarantee task completion for tasks that require cycles the worker doesn't have.

**Implementation**: `src/invariant/nonnegativeBalance.m`

**Check Frequency**: Every consumption attempt, every transfer

**Violation Recovery**: Reject the operation; do not proceed with consumption/transfer

```matlab
[ledger, success, eventId] = ledger.consume(ledger, workerId, cycles);
if ~success
    % Consumed would go negative - operation rejected
end
```

## I3: Queue Integrity

**Statement**: `∀ task t: appears in at most one worker's queue`

**Meaning**: No task simultaneously exists in multiple worker queues. Each task has a single location.

**Rationale**: A task cannot be executed by two workers simultaneously. Double-queueing creates scheduling ambiguity and impossible execution semantics.

**Implementation**: `src/invariant/queueIntegrity.m`

**Check Frequency**: Every enqueue/dequeue/balance operation

**Violation Recovery**: Detect and repair by removing duplicate; report as data corruption

```matlab
[pass, diag] = invariant.queueIntegrity(queues);
if ~pass
    fprintf('Queue corruption detected: %s\n', diag.message);
end
```

## I4: Replay Consistency

**Statement**: `Replay of identical event sequence → identical final state`

**Meaning**: The system is deterministic. If we replay the exact same sequence of operations, we must get the exact same result.

**Rationale**: Non-determinism would make experiments non-reproducible and hide race conditions or hidden state dependencies.

**Implementation**: `src/invariant/replayConsistency.m`

**Verification**:
```matlab
% Record original execution
[ledger1, queues1, results1] = runExperiment(config);
snap1 = ledger.snapshot(ledger1);

% Replay with same seed
[ledger2, queues2, results2] = runExperiment(config);
snap2 = ledger.snapshot(ledger2);

% Verify identical final state
[pass, diag] = invariant.replayConsistency(snap1, snap2);
assert(pass, 'Replay consistency violated');
```

## I5: Determinism

**Statement**: `Identical seed + config → identical execution trace`

**Meaning**: Same inputs always produce same outputs. The RNG is deterministic.

**Rationale**: Allows reproducible experiments and enables replay-based verification.

**Implementation**: Achieved through:
- Deterministic RNG seeding
- Event log ordering determinism
- No floating-point accumulated errors (use integer cycles)

## I6: Latency Bound

**Statement**: `∀ task t: completionTime(t) - startTime(t) <= workerTimeoutCycles`

**Meaning**: All tasks must complete within configured latency bound.

**Rationale**: Prevents tasks from becoming stuck or experiencing unbounded delays.

**Implementation**: `src/invariant/latencyBound.m`

**Configuration**:
```matlab
config.workerTimeoutCycles = 1000; % Maximum cycles per task
```

## I7: Throughput Target

**Statement**: `totalTasksCompleted / executionSteps >= targetThroughput`

**Meaning**: System achieves configured throughput target.

**Rationale**: Validates that scheduling/stealing policy actually improves performance.

**Note**: Unlike invariants I1-I6 which are hard constraints, I7 is a performance target. Failure indicates policy ineffectiveness, not system corruption.

## I8: Recursion Bound

**Statement**: `maxDepthReached <= maxRecursionDepth AND totalNodes <= maxTotalNodes`

**Meaning**: Recursive exploration respects configured depth and node count limits.

**Rationale**: Prevents exponential explosion of recursive tree. Ensures bounded execution time.

**Implementation**: `src/invariant/recursionBound.m`

**Configuration**:
```matlab
config.maxRecursionDepth = 5;      % Maximum recursion depth
config.maxTotalNodes = 100;         % Maximum total nodes in tree
```

## I9: Candidate Integrity

**Statement**: `∀ candidate c: hasValidConfig(c) AND hasEvaluationRecord(c)`

**Meaning**: Every Mythos candidate has:
- A valid configuration (passes validateConfig)
- An evaluation record with measurements

**Rationale**: Prevents orphaned candidates or incomplete evaluations.

**Implementation**: `src/invariant/candidateIntegrity.m`

## I10: Experiment Closure

**Statement**: `Every started experiment → completed with final result record`

**Meaning**: No zombie experiments. Every experiment either:
- Completes successfully with result saved, or
- Fails with explicit error and diagnostic

**Rationale**: Enables audit trail and prevents data loss from incomplete runs.

**Implementation**: All experiments wrapped in try/catch:
```matlab
function result = run_experiment(config)
    result = struct();
    try
        % ... execution ...
        result.status = 'success';
    catch ME
        result.status = 'failed';
        result.error = ME.message;
    end
    result.timestamp = datetime('now');
    result.experimentId = config.experimentId;
end
```

## Invariant Hierarchy

Not all invariants have equal priority:

### Critical (execution-halting)
- I1: Cycle Conservation
- I2: Nonnegative Balances
- I3: Queue Integrity

These must never be violated. System halts if any critical invariant is broken.

### Strong (policy-enforcing)
- I4: Replay Consistency
- I5: Determinism
- I6: Latency Bound
- I8: Recursion Bound

These are preconditions for valid experiments. Violation indicates data corruption or configuration error.

### Soft (performance targets)
- I7: Throughput Target
- I9: Candidate Integrity
- I10: Experiment Closure

These indicate policy effectiveness or data completeness. Violations reported but don't halt execution.

## Validation Strategy

### Continuous Validation (Critical Invariants)
```matlab
if mod(step, config.invariantCheckFrequency) == 0
    [inv_pass, results] = invariant.assertInvariant(ledger, queues, config);
    if ~inv_pass && config.failOnInvariantViolation
        error('Critical invariant violation at step %d', step);
    end
end
```

### Pre-Execution Validation
```matlab
[valid, issues] = utils.validateConfig(config);
if ~valid
    error('Invalid configuration:\n%s', sprintf('%s\n', issues{:}));
end
```

### Post-Execution Validation
```matlab
[ledger, snap] = ledger.validate(ledger);
[pass, diag] = invariant.replayConsistency(snap_original, snap_final);
```

## Diagnostic Output

Each invariant violation generates structured diagnostics:

```matlab
diagnostic = struct();
diagnostic.invariant = 'I1_CycleConservation';
diagnostic.timestamp = datetime('now');
diagnostic.totalInitialCycles = 1000000;
diagnostic.accountedCycles = 999999;
diagnostic.difference = 1;  % VIOLATION
diagnostic.message = 'Conservation violated: total=1000000, accounted=999999';
```

These diagnostics are:
- Logged to results
- Saved to persistent storage
- Reported in CI/CD pipeline
- Used for post-mortem analysis

## Adding New Invariants

To add a new invariant:

1. Define the mathematical statement
2. Implement check function in `src/invariant/`
3. Register in `invariant.assertInvariant()`
4. Add test case to `tests/TestInvariant.m`
5. Document in this file
6. Add CI check if applicable

Example:
```matlab
function [pass, diagnostic] = myNewInvariant(state)
    diagnostic = struct();
    diagnostic.invariant = 'I11_MyNewInvariant';
    
    % Check condition
    condition = (state.property1 == state.property2);
    pass = condition;
    
    diagnostic.pass = pass;
    if ~pass
        diagnostic.message = 'Condition violated';
    end
end
```

## Verification Guarantees

These invariants together guarantee:

1. **Resource Correctness**: No cycle leaks or creation
2. **Execution Correctness**: Tasks don't race, no double-execution
3. **Reproducibility**: Same seed = same result
4. **Determinism**: No undefined behavior
5. **Progress**: Tasks complete with bounded latency
6. **Recursion Safety**: Bounded expansion
7. **Data Integrity**: Complete evaluation records

A system that maintains all invariants is guaranteed to produce valid, reproducible experiments.
