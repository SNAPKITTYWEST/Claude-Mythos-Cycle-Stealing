# Implementation Notes

This document describes the implementation architecture, key decisions, and engineering practices.

## Core Design Principles

### 1. Determinism-First Architecture

Every decision made with determinism as primary requirement. This enables:
- Bit-exact reproducibility
- Perfect replay verification
- Non-determinism detection
- Parallelization without race conditions

**Implementation Strategy**:
- Deterministic RNG seeding (MT19937 with explicit seed)
- Integer-only cycle accounting (no floating-point)
- Explicit event logging (every state change recorded)
- Event sequence ordering (deterministic progression)

### 2. Explicit State Over Hidden Logic

All state changes generate explicit events:

```matlab
% NOT:
worker.cycleCount = worker.cycleCount - 100;

% INSTEAD:
[ledger, success, eventId] = ledger.consume(ledger, workerId, 100);
% Event automatically logged to ledger.events
```

Benefits:
- Complete auditability
- Easy replay verification
- Clear cause-effect tracing
- Reproducibility verification

### 3. Conservative Resource Management

Cycles are finite resources with conservation law I1:

```
totalInitialCycles == allocatedCycles + availableCycles (always)
```

Never:
- Create cycles
- Destroy cycles
- Lose cycles
- Overspend cycles (I2)

Checking:
- Every transfer validated for sufficiency
- I1 checked periodically
- I2 checked at every consumption

### 4. Bounded Execution

All loops and recursion bounded explicitly:

- Recursion depth <= config.maxRecursionDepth
- Total nodes <= config.maxTotalNodes
- Event log <= config.maxEvents
- Execution steps <= max_steps (safety limit)

Prevents:
- Infinite loops
- Stack overflow
- Memory exhaustion
- Runaway processes

### 5. Machine-Checkable Invariants

10 core invariants validated continuously:

```matlab
% Continuous checking
if mod(step, config.invariantCheckFrequency) == 0
    [all_pass, results] = invariant.assertInvariant(ledger, queues, config);
    if ~all_pass && config.failOnInvariantViolation
        error('Invariant violation at step %d', step);
    end
end
```

Benefits:
- Catch bugs immediately
- No silent corruption
- Clear failure diagnostics
- Confidence in results

## Architecture Layers

### Layer 1: Core Accounting (ledger/)

**Responsibility**: Absolute cycle conservation

**Components**:
- `create()` - Initialize ledger
- `allocate()` - Reserve cycles
- `consume()` - Use cycles
- `transfer()` - Move cycles (stealing)
- `returnCycles()` - Return unused
- `validate()` - Check conservation

**Invariants**:
- I1: Conservation (cycles never created/destroyed)
- I2: Non-negativity (no negative balances)
- Event consistency (every operation logged)

**No Dependencies**: Ledger is self-contained, no other modules needed

### Layer 2: Execution Control (scheduler/, stealing/)

**Responsibility**: Task scheduling and load balancing

**Components**:
- Queue management (enqueue, dequeue, peek)
- Load balancing (balance, priority assignment)
- Stealing policies (random, bounded, priority, recursive)

**Dependencies**: Ledger for cycle tracking

**Invariants**:
- I3: Queue integrity (no duplicate tasks)
- Stealing maintains I1 and I2

### Layer 3: Workload Execution (kernels/)

**Responsibility**: Representative computational work

**Components**:
- Matrix multiply, FFT, convolution, sort, reduction
- Deterministic input generation
- Cycle estimation
- Checksum validation

**Dependencies**: Ledger for cycle consumption tracking

**Invariants**:
- Checksums validate kernel correctness
- Cycle estimates consistent

### Layer 4: Validation (invariant/)

**Responsibility**: Machine-checkable invariants

**Components**:
- 10 core invariant checks
- Structured diagnostics
- Violation reporting

**Dependencies**: All other layers for comprehensive checking

### Layer 5: Experiment Management (experiment/, execution/)

**Responsibility**: Orchestrate complete executions

**Components**:
- Initialize system
- Execute simulation loop
- Collect statistics
- Generate reports

**Dependencies**: All layers

## Algorithm Details

### Cycle Stealing Algorithm

**Bounded Policy** (most practical):

```
for each worker w:
    if w.cycles < mean - stealThreshold * mean:
        for each donor d with d.cycles > maxStealPerOp:
            if d.cycles - transfer > threshold * mean:
                transfer_cycles = min(maxSteal, (d.cycles - w.cycles) / 2)
                ledger.transfer(d, w, transfer_cycles)
                break
```

Properties:
- O(workers) per stealing pass
- Threshold prevents excessive stealing
- Respects nonnegative balance (I2)
- Maintains conservation (I1)

### Scheduler Step Algorithm

```
1. Check if rebalancing needed (queue depth variance)
2. If imbalanced:
   - Balance queues (move tasks from overloaded to underloaded)
3. For each worker with available cycles:
   - If task in queue: mark for execution
4. Return scheduling decisions
```

Properties:
- O(workers) per step
- Deterministic decision-making
- Clear cause-effect

### Replay Algorithm

```
for each event in event_log:
    switch event.operation:
        case 'allocate':
            ledger.allocate(event.workerId, event.cycles)
        case 'consume':
            ledger.consume(event.workerId, event.cycles)
        case 'steal':
            ledger.transfer(event.donor, event.thief, event.cycles)
        case 'return':
            ledger.returnCycles(event.workerId, event.cycles)

compare final state to original state
```

Properties:
- Exact reproducibility verification
- O(events) time
- Detects non-determinism

## Data Structure Choices

### Ledger

**Structure**:
```matlab
ledger.totalInitialCycles      % uint64 (immutable)
ledger.allocatedCycles         % uint64
ledger.availableCycles         % uint64
ledger.workerCycles            % uint64 array
ledger.events                  % struct array
ledger.eventCount              % uint64
```

**Rationale**:
- Integer arithmetic (no floating-point rounding)
- Explicit fields (no hidden state)
- Immutable initial allocation (can't change requirements)
- Event log for auditability

### Event

**Structure**:
```matlab
event.eventId                  % uint64
event.timestamp                % datetime
event.operation                % string
event.workerId                 % uint32
event.cycles                   % uint64
event.source, destination      % uint32
event.previousBalance          % uint64
event.newBalance               % uint64
```

**Rationale**:
- Sufficient to reconstruct state
- Pre/post state for verification
- Timestamp for logging (not used for determinism)
- Immutable after creation

### Worker

**Structure**:
```matlab
worker.workerId                % uint32
worker.cycleCount              % uint64
worker.tasksCompleted          % uint64
worker.cyclesConsumed          % uint64
worker.cyclesStolen            % uint64
worker.cyclesReceived          % uint64
worker.latencySum              % uint64
```

**Rationale**:
- Tracking both cycles and tasks
- Separate stealing/receiving metrics
- Latency accumulation for statistics
- All numeric for reproducibility

## Testing Strategy

### Unit Tests (src/*)

Test each module independently:
- Ledger: allocate, consume, transfer, validate
- Scheduler: enqueue, dequeue, balance
- Stealing: each policy independently
- Kernels: determinism, checksums
- Invariants: detection and diagnostics

### Integration Tests (tests/)

Test module interactions:
- Scheduler + Ledger
- Stealing + Ledger
- Full experiment execution
- Multi-policy comparison

### System Tests

- Baseline reproducibility
- Stealing policy correctness
- Invariant robustness
- CI/CD pipeline

### Determinism Tests

- Same seed → same results
- Replay produces exact match
- Configuration immutability
- RNG isolation

## Performance Optimization

### Computational Efficiency

**Cycle Ledger O(1) operations**:
- Allocation: direct array access
- Consumption: direct array access
- Transfer: two array updates
- Balance checking: O(workers) scan

**Scheduler O(1) amortized**:
- Enqueue: append to vector
- Dequeue: pop from front
- Balance: O(workers) per trigger

**Stealing O(workers)**:
- Find eligible donors: O(workers)
- Select and transfer: O(1)

**Overall**: O(workers) per main loop iteration

### Memory Efficiency

**Event Log**: ~100 bytes per event
- 1M event log: ~100 MB
- Sparse (not all cycles logged, just allocation/consumption)

**Ledger**: ~1 KB + event log
**Workers**: ~1 KB per worker

**Total**: 10-100 MB typical execution

### Scalability

**Workers**: Linear O(workers)
- Tested: 2 to 32 workers
- Expected limit: 128+ (MATLAB limitation)

**Cycles**: No dependence on cycle count
- Only event count matters
- 1M to 1B cycles same execution time

**Events**: Linear O(events)
- Replay: O(events)
- Validation: O(events)
- Statistics: O(events)

## Error Handling

### Principle: Fail Fast

Invalid operations rejected immediately:

```matlab
% Don't silently repair
if cycles > workerCycles
    return success = false
end

% Don't continue with corruption
if ~invariant_pass
    error('Invariant violation')
end
```

### Error Categories

1. **Configuration Errors**: Caught at startup (validateConfig)
2. **Operation Errors**: Rejected at operation time (consume fails if insufficient)
3. **Invariant Violations**: Halt immediately (critical invariants) or report (soft invariants)
4. **State Corruption**: Detected and reported (never silently repaired)

### Diagnostics

Every error includes:
- What went wrong (clear message)
- Where it happened (file, function, line)
- Why it matters (consequence)
- How to fix (suggestion if possible)

## Extensions

### Adding New Stealing Policy

1. Create `src/stealing/+stealing/myPolicy.m`
2. Implement `[ledger, steal_events] = myPolicy(ledger, config)`
3. Register in `policyFactory.m`
4. Add test in `tests/TestStealing.m`

**Requirements**:
- Maintain I1 and I2 invariants
- Return structured steal_events
- Be deterministic (use RNG seed)
- No external dependencies

### Adding New Kernel

1. Create `src/kernels/+kernels/myKernel.m`
2. Implement `[result, metadata] = myKernel(size, reps)`
3. Register in `benchmarkKernel.m`
4. Add test in `tests/TestKernels.m`

**Requirements**:
- Return cycles estimate
- Return metadata with checksums
- Be deterministic
- No external dependencies

### Adding New Invariant

1. Create `src/invariant/+invariant/myInvariant.m`
2. Implement `[pass, diagnostic] = myInvariant(state)`
3. Register in `assertInvariant.m`
4. Add test in `tests/TestInvariant.m`
5. Document in `docs/invariants.md`

## Deployment

### CI/CD Pipeline

`run_ci.m` executes:
1. Repository structure audit
2. MATLAB-only verification
3. Python removal audit
4. Line count (>= 10,000)
5. Function count (>= 100)
6. License verification
7. Invariant coverage

**All checks must pass** for release.

### Distribution

- Single GitHub repository
- Self-contained (no external deps)
- Dual licensing
- Complete documentation
- Full test coverage

### Compatibility

- MATLAB R2019a or later
- Windows/Linux/macOS
- No toolbox dependencies
- Pure .m files

## Maintenance

### Code Organization

```
src/
├── ledger/          - Core accounting
├── scheduler/       - Task queuing
├── stealing/        - Load balancing
├── kernels/         - Workloads
├── invariant/       - Validation
├── recursion/       - Tree exploration
├── mythos/          - Candidate search
├── execution/       - Main loop
├── statistics/      - Analysis
├── experiment/      - Registry
├── visualization/   - Plotting
├── persistence/     - Save/load
└── utilities/       - Helpers
```

### Naming Conventions

- Functions: `verbNoun()` (allocate, dequeue, validateConfig)
- Variables: `camelCase` (workerCount, stealThreshold)
- Constants: `UPPER_CASE` (maxEvents, maxRecursionDepth)
- Private: No prefix (MATLAB convention)

### Documentation

- Inline comments: Why, not what (code shows what)
- Module README: Architecture and design
- API docs: Function signatures and examples
- Design docs: Principles and tradeoffs

## Known Limitations

1. **Single-threaded**: MATLAB limitation, no true parallelism
2. **Event log memory**: Large experiments need >100 MB
3. **Worker count**: Practical limit ~32 workers
4. **Cycle count**: No upper limit, but large counts mean more events
5. **Kernel implementations**: Simplified models, not actual hardware behavior

## Future Enhancements

1. **Visualization**: More plot types, real-time monitoring
2. **Advanced Mythos**: Genetic algorithms, simulated annealing
3. **Additional policies**: Work stealing, hierarchical, affinity-aware
4. **Parallel evaluation**: Use MATLAB Parallel Computing Toolbox
5. **Hardware integration**: Connect to real cycle counter
6. **GUI**: Visual experiment builder and results viewer

## Research Applications

This framework enables:
- Scheduling algorithm research
- Load balancing studies
- Resource allocation optimization
- Performance prediction
- Algorithm comparison
- Reproducible benchmarking

## References

### Key Papers

- Cilk: work-stealing scheduler for DAGs
- Work-first principle: load balancing through stealing
- Deterministic replay: record-and-replay verification
- Invariant-based testing: machine-checkable properties

### MATLAB Documentation

- Data structures and performance
- Event-based architecture
- Deterministic random number generation
- Testing framework

---

**Framework Version**: 0.1.0  
**Last Updated**: 2026-09-19  
**Maintainer**: SNAPKITTY Research
