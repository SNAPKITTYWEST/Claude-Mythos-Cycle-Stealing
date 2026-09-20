# Design Document

## System Overview

The MATLAB Cycle-Stealing and Recursive Mythos Framework is a deterministic experimental infrastructure for studying resource scheduling strategies. It implements:

1. **Explicit Cycle Accounting** - Every cycle is tracked through a ledger system
2. **Multiple Scheduling Policies** - Flexible scheduler with pluggable policies
3. **Cycle Stealing Strategies** - Random, bounded, priority, and recursive stealing
4. **Computational Kernels** - Representative workloads (matrix multiply, FFT, etc.)
5. **Machine-Checkable Invariants** - 10 core invariants validated throughout execution
6. **Reproducibility Guarantee** - Bit-exact reproducibility from seed and config
7. **Recursive Exploration** - Bounded recursion for tree-based search
8. **Mythos Engine** - Candidate generation and evaluation for architecture exploration

## Design Principles

### 1. Determinism First

**Principle**: All results must be reproducible from seed and configuration.

**Implementation**:
- Deterministic RNG seeding
- Explicit event logging
- Integer-only accounting (no floating-point)
- No timestamp dependencies

**Benefit**: Enables perfect replay verification and non-determinism detection.

### 2. Explicit State

**Principle**: No hidden state changes. All operations generate logged events.

**Implementation**:
- Every cycle allocation/consumption/transfer generates an event
- Events include pre-state and post-state
- Event log is immutable after execution

**Benefit**: Complete auditability and replay capability.

### 3. Conservative Resource Management

**Principle**: Resources (cycles) cannot be created, destroyed, or lost.

**Implementation**:
- Cycle conservation invariant (I1) checked frequently
- Cycle transfers validate source has sufficient balance
- No overspending allowed (I2)

**Benefit**: Prevents resource leaks and hidden accounting errors.

### 4. Bounded Execution

**Principle**: All execution is bounded by explicit limits.

**Implementation**:
- Recursion depth limited by config
- Node count limited by config
- Event log size limited
- Maximum execution steps limit

**Benefit**: Prevents infinite loops or resource exhaustion.

### 5. Invariant Validation

**Principle**: Machine-checkable invariants validated continuously.

**Implementation**:
- 10 core invariants defined formally
- Checked at configurable frequency
- Failures halt execution (for critical invariants)
- All results include invariant validation report

**Benefit**: Detects corruption immediately rather than silently propagating.

### 6. Pluggable Policies

**Principle**: Scheduling and stealing policies are interchangeable.

**Implementation**:
- Policy factory pattern (policyFactory.m)
- Each policy has identical interface
- New policies added without modifying core

**Benefit**: Easy to add new strategies without touching infrastructure.

### 7. Complete Instrumentation

**Principle**: Full visibility into system behavior.

**Implementation**:
- Event logging (allocation, consumption, stealing)
- Queue state snapshots
- Worker utilization tracking
- Stealing event recording

**Benefit**: Enables post-mortem analysis and debugging.

## Architecture Patterns

### 1. Module Organization

```
src/
├── ledger/        - Cycle accounting system
├── scheduler/     - Queue management and scheduling
├── stealing/      - Cycle stealing policies
├── kernels/       - Computational workloads
├── invariant/     - Invariant validation
├── recursion/     - Recursive tree management
├── mythos/        - Candidate exploration
├── execution/     - Execution loop
├── statistics/    - Analysis and reporting
├── experiment/    - Experiment registry
├── visualization/ - Plotting and visualization
├── persistence/   - Save/load functionality
└── utilities/     - Helper functions
```

### 2. Data Flow

```
Configuration
    ↓
Initialize System (Ledger + Queues + Workers)
    ↓
Main Loop
    ├─ Scheduling Step
    ├─ Execution Step
    ├─ Stealing Step (if enabled)
    ├─ Task Generation
    └─ Invariant Check
    ↓
Finalize (Statistics + Validation)
    ↓
Results (Ledger + Stats + Invariants)
```

### 3. State Representation

**Ledger** (src/ledger/)
```matlab
ledger.totalInitialCycles      - Total cycles (constant)
ledger.allocatedCycles         - Currently allocated to workers
ledger.availableCycles         - In available pool
ledger.consumedCycles          - Used by kernels
ledger.stolenCycles            - Transferred via stealing
ledger.workerCycles            - Per-worker budgets
ledger.events                  - Immutable event log
```

**Queues** (src/scheduler/)
```matlab
queues.type                    - 'FIFO' or 'Priority'
queues.workerQueues            - Per-worker task queue
queues.taskLocation            - Where each task lives
queues.events                  - Scheduling events
```

**Workers** (src/execution/)
```matlab
workers(i).workerId            - Worker ID
workers(i).cycleCount          - Current cycle budget
workers(i).tasksCompleted      - Task count
workers(i).cyclesConsumed      - Cycles spent
```

## Configuration Strategy

### Principle: Single Point of Control

All experiment parameters in `defaultConfig.m`. When creating specialized configs:

```matlab
config = defaultConfig();
config.experimentType = 'custom';
config.stealingPolicy = 'bounded';
config.maxRecursionDepth = 7;
```

### Config Categories

1. **Cycle Parameters**
   - Total cycles, per-worker allocation, steal thresholds

2. **Worker Configuration**
   - Count, queue type, timeout

3. **Scheduler Parameters**
   - Type, period, rebalance threshold

4. **Stealing Policy**
   - Type, probability, max simultaneous steals

5. **Kernels**
   - Type, size, repetitions

6. **Recursion**
   - Depth limit, node count limit, budget

7. **Mythos**
   - Candidate count, mutation rate, evaluation reps

8. **Execution**
   - Task parameters, failure rates

9. **Persistence**
   - Output directories, saving options

10. **Validation**
    - Invariant frequency, failure handling

## Testing Strategy

### Test Categories

1. **Unit Tests** (src/*/+*/)
   - Individual module functionality
   - Invariant checking

2. **Integration Tests** (tests/)
   - Multi-module interactions
   - End-to-end experiment execution

3. **Determinism Tests**
   - Reproducibility verification
   - Replay consistency

4. **Failure Injection**
   - Corruption detection
   - Invalid state handling

### Test Execution

```matlab
% Run all tests
run_tests

% Individual test class
run(matlab.unittest.TestLoader().loadTestsFromTestCase(?TestLedger))
```

## Performance Considerations

### Cycle Ledger
- Allocation: O(1)
- Consume: O(1)
- Transfer: O(1)
- Validation: O(workers)
- Snapshot: O(workers + events)

### Scheduler
- Enqueue: O(1) amortized
- Dequeue: O(1) amortized
- Balance: O(workers^2)
- Priority: O(tasks log tasks)

### Stealing Policies
- Random: O(workers)
- Bounded: O(workers)
- Priority: O(workers log workers)
- Recursive: O(depth × workers)

### Scaling
- Workers: Linear scaling up to 32+
- Tasks: 100K+ completions tested
- Events: Up to 1M events supported
- Memory: Sparse event storage

## Error Handling

### Strategy: Fail Fast

Invalid operations rejected immediately:

```matlab
[ledger, success, eventId] = ledger.consume(ledger, workerId, cycles);
if ~success
    % Insufficient cycles - operation rejected
    % Ledger unchanged
end
```

### Invariant Violations

**Critical Invariants** (I1, I2, I3): Fatal
- Ledger corruption detected
- Execution halted immediately
- Error message with diagnostics

**Strong Invariants** (I4, I5, I6, I8): Fatal if configured
- Configuration: `config.failOnInvariantViolation = true`

**Soft Invariants** (I7, I9, I10): Reported
- Don't halt execution
- Logged in results

## Extension Mechanisms

### Adding New Stealing Policy

1. Create function in `src/stealing/`
   ```matlab
   function [ledger, steal_events] = myPolicy(ledger, config)
       % Implementation
   end
   ```

2. Register in `policyFactory.m`
   ```matlab
   case 'my_policy'
       [ledger, steal_events] = stealing.myPolicy(ledger, config);
   ```

3. Add test in `tests/TestStealing.m`

### Adding New Kernel

1. Create function in `src/kernels/`
   ```matlab
   function [result, metadata] = myKernel(size, reps)
       % Implementation
       % Return result with cycles estimate
       % Return metadata with checksums
   end
   ```

2. Register in `benchmarkKernel.m`
   ```matlab
   case 'my_kernel'
       [result, metadata] = kernels.myKernel(kernelSize, reps);
   ```

3. Add test in `tests/TestKernels.m`

### Adding New Invariant

1. Create function in `src/invariant/`
   ```matlab
   function [pass, diagnostic] = myInvariant(state)
       % Check condition
       % Return pass/fail + diagnostics
   end
   ```

2. Register in `assertInvariant.m`
   ```matlab
   [results.I11_pass, results.I11_diag] = invariant.myInvariant(state);
   ```

3. Add test and documentation

## Reproducibility Verification

### Method 1: Configuration Match

```matlab
result1 = run_experiment('baseline');
result2 = run_experiment('baseline');
assert(result1.config.seed == result2.config.seed);
```

### Method 2: Replay Verification

```matlab
result = run_experiment('baseline');
[ledger_replayed, match, diag] = ledger.replay(result.ledger.events, config);
assert(match);
```

### Method 3: Checksum Comparison

```matlab
snap1 = ledger.snapshot(result1.ledger);
snap2 = ledger.snapshot(result2.ledger);
assert(snap1.stateHash == snap2.stateHash);
```

## Security Considerations

### No Python Execution

- Audit removes all Python infrastructure
- Subprocess calls forbidden
- Benefits: Complete MATLAB-only self-containment

### No External Dependencies

- All functionality in MATLAB
- No external libraries
- Benefits: Reproducibility, portability

### Resource Limits

- Event log capped at 1M events
- Max 32 workers configurable
- Max recursion depth enforced
- Benefits: Prevents resource exhaustion

## Maintenance and Evolution

### Backward Compatibility

- Configuration format stable
- Public API (run_experiment, etc.) stable
- Internal modules subject to change

### Version Control

- Dual licensing: BSD-3 and GPL-1.0
- Git history preserved
- All changes documented

### Documentation

- Architecture (docs/architecture.md)
- Invariants (docs/invariants.md)
- Design (docs/design.md)
- Reproducibility (docs/reproducibility.md)
- Experiments (docs/experiments.md)
