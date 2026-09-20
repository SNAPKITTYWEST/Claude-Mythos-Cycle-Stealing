# System Architecture

## Overview

The MATLAB Cycle-Stealing and Recursive Mythos Framework implements a complete, deterministic experimental system for studying:

1. Cycle allocation and accounting
2. Deterministic scheduling policies
3. Cycle stealing strategies
4. Computational kernel execution
5. Invariant validation
6. Recursive exploration
7. Mythos candidate generation and evaluation

## Core Components

### 1. Cycle Ledger (`src/ledger/`)

The cycle ledger is the foundation of the entire system. It maintains absolute cycle conservation (I1 invariant).

**Key Operations:**
- `create()` - Initialize ledger with total cycles
- `allocate()` - Assign cycles to workers
- `consume()` - Remove cycles from worker budget
- `transfer()` - Move cycles between workers (stealing)
- `returnCycles()` - Return unused cycles to available pool
- `snapshot()` - Create point-in-time ledger snapshot
- `validate()` - Check all invariants
- `replay()` - Re-execute event sequence for determinism verification

**Invariants Maintained:**
- I1: Cycle Conservation (total = allocated + available)
- I2: Nonnegative Balances (all worker cycles >= 0)
- I3: Event Consistency

### 2. Scheduler (`src/scheduler/`)

The scheduler manages work queues and dispatch decisions.

**Queue Operations:**
- `enqueue()` - Add task to worker queue
- `dequeue()` - Remove next task (FIFO)
- `peek()` - Examine next task without dequeuing
- `isEmpty()` - Check if queue is empty
- `getQueueSize()` - Get current queue depth
- `queueState()` - Get complete queue state snapshot

**Scheduling:**
- `balance()` - Rebalance load across workers
- `priorityAssign()` - Assign priority to tasks
- `schedulerStep()` - Execute one scheduling decision

### 3. Stealing Engine (`src/stealing/`)

Multiple cycle-stealing policies for load balancing.

**Policies:**
- `randomPolicy()` - Probabilistic stealing
- `boundedPolicy()` - Threshold-based stealing
- `priorityPolicy()` - Priority-weighted stealing
- `recursivePolicy()` - Recursive stealing with depth limit
- `policyFactory()` - Dispatch to selected policy
- `stealStep()` - Execute stealing round

### 4. Computational Kernels (`src/kernels/`)

Diverse workloads for benchmarking:

- `matrixMultiply()` - Dense matrix multiplication
- `fftKernel()` - Fast Fourier Transform
- `convolution()` - Signal convolution
- `sortKernel()` - Array sorting
- `reduction()` - Sum reduction
- `benchmarkKernel()` - Unified kernel interface

Each kernel returns estimated cycles and metadata for deterministic simulation.

### 5. Invariant Engine (`src/invariant/`)

Machine-checkable invariants validated throughout execution:

- **I1** - `cycleConservation()` - Cycle accounting
- **I2** - `nonnegativeBalance()` - No negative balances
- **I3** - `queueIntegrity()` - Tasks not in multiple queues
- **I4** - `replayConsistency()` - Replay reproducibility
- **I6** - `latencyBound()` - Task completion latency
- **I8** - `recursionBound()` - Recursion depth limits

### 6. Execution Model

Main execution pipeline (`run_experiment.m`):

```
Initialize System
    ├─ Create Ledger
    ├─ Allocate Cycles to Workers
    ├─ Initialize Work Queues
    └─ Create Worker State

Main Simulation Loop
    ├─ Scheduling Step
    │   ├─ Check Queue Balance
    │   └─ Make Scheduling Decisions
    ├─ Task Execution
    │   ├─ Dequeue Task
    │   ├─ Execute Kernel
    │   └─ Consume Cycles
    ├─ Cycle Stealing (if enabled)
    │   └─ Apply Stealing Policy
    ├─ Task Generation
    │   └─ Create New Tasks
    └─ Invariant Validation
        └─ Check All Invariants

Finalize
    ├─ Collect Statistics
    ├─ Validate Invariants
    └─ Generate Report
```

## Configuration System

`config/defaultConfig.m` defines all experiment parameters:

- **Cycle Allocation**: Total cycles, per-worker allocation, steal thresholds
- **Worker Configuration**: Worker count, queue type, timeout
- **Scheduler Parameters**: Type, period, rebalance threshold
- **Stealing Policies**: Type, probability, max simultaneous steals, recursion depth
- **Kernels**: Type, size, repetitions
- **Recursion**: Depth limit, node count limit, budget
- **Mythos**: Candidate count, mutation rate, evaluation repetitions
- **Force Mode**: Pressure multipliers, safety limits
- **Execution**: Task parameters, failure rates, generation model
- **Persistence**: Output directories, trace saving, figure generation
- **Validation**: Invariant checking frequency, failure handling

## Determinism Guarantee

Complete bit-exact reproducibility through:

1. **Deterministic RNG** - Seeded MT19937 generator
2. **Event Logging** - Every action logged with full state
3. **Replay Verification** - Re-execute logged events, verify identical final state
4. **Checksum Validation** - Kernel outputs checksummed for corruption detection
5. **Timestamped Events** - Each event timestamped but determinism verified by event sequence, not timestamps

## Experiment Types

### Baseline
- Balanced scheduler
- No cycle stealing
- Reference for comparison

### Random Stealing
- Probabilistic stealing attempts
- Random donor/recipient selection

### Bounded Stealing
- Load-difference threshold
- Steal only when load exceeds threshold
- Conservative approach

### Priority Stealing
- Workers prioritized by load metrics
- More sophisticated donor/recipient selection

### Recursive Stealing
- Stealing triggers additional scheduling
- Recursive depth limit controls expansion
- Bounded by recursion parameters

### Force Mode
- Increased stealing pressure
- Increased scheduling frequency
- Stress testing with safety limits

### Recursive Mythos
- Recursive task tree exploration
- Candidate generation and evaluation
- Architecture space search

## Scaling Characteristics

- **Workers**: Scales to 32+ with queue management
- **Tasks**: Tested to 100K+ task completions
- **Event Log**: Configurable, up to 1M events
- **Memory**: Efficient sparse event storage
- **Time**: O(steps * workers) execution model

## Testing Framework

Full MATLAB test suite in `tests/`:

- TestLedger - Cycle accounting and conservation
- TestScheduler - Queue operations and balance
- TestStealing - Stealing policy correctness
- TestKernels - Kernel execution and checksums
- TestInvariant - Invariant validation
- TestRecursion - Recursion bounding
- TestDeterminism - Reproducibility
- TestPersistence - Save/load cycles
- TestReplay - Event replay verification
- TestFailureInjection - Corruption detection

## CI/CD Pipeline

`ci/run_ci.m` executes:

1. Repository structure audit
2. MATLAB-only verification
3. Python removal audit (forbidden pattern detection)
4. Line count audit (>= 10,000 lines)
5. Function count audit (>= 100 functions)
6. License audit (dual license verification)
7. Invariant coverage audit

All checks must pass for CI success.

## Performance Characteristics

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
- Priority assignment: O(log tasks)

### Stealing
- Random policy: O(workers)
- Bounded policy: O(workers)
- Priority policy: O(workers log workers)
- Recursive policy: O(depth * workers)

## Extension Points

The framework is designed for extensibility:

1. **New Stealing Policies**: Implement in `src/stealing/`
2. **New Kernels**: Add to `src/kernels/`, register in benchmarkKernel
3. **New Invariants**: Add to `src/invariant/`, register in assertInvariant
4. **New Visualizations**: Add to `src/visualization/`
5. **New Experiment Types**: Configure in defaultConfig, dispatch in run_experiment

## Reproducibility Guarantee

Any experiment can be exactly reproduced:

```matlab
% Save original result
result1 = run_experiment('baseline');
config1 = result1.config;

% Later: reproduce exact same experiment
config2 = config1; % Same configuration
config2.experimentId = 'reproduction'; % New ID
config2.seed = config1.seed; % Same seed

result2 = run_experiment('baseline');

% Verify reproducibility
assert(result1.ledger.consumedCycles == result2.ledger.consumedCycles);
assert(all(result1.ledger.workerCycles == result2.ledger.workerCycles));
```

## Design Decisions

1. **MATLAB Only** - No external dependencies, complete self-containment
2. **Explicit State** - All state logged, no hidden decision logic
3. **Conservative Stealing** - Steal operations validate all preconditions
4. **Instrumentation** - Every operation recorded for full visibility
5. **Determinism First** - Reproducibility built into core design
6. **Invariant Checking** - Validation throughout execution, not post-hoc
7. **Dual Licensing** - BSD-3 and GPL-1.0 for maximum compatibility
