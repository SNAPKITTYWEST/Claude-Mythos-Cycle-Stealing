# MATLAB Cycle-Stealing & Recursive Mythos Framework

A deterministic, instrumented experimental framework for studying cycle-stealing schedulers, recursive control, and Mythos candidate exploration in MATLAB.

## Quick Start

```matlab
% Run all experiments
run_all

% Run specific experiment
run_experiment('baseline')

% Run tests
run_tests

% Run benchmarks
run_benchmarks
```

## Features

- **Cycle Ledger**: Complete cycle accounting with conservation invariants
- **Deterministic Scheduler**: Multiple scheduling policies with full instrumentation
- **Cycle-Stealing Engine**: Random, bounded, priority, and recursive stealing policies
- **Computational Kernels**: Matrix multiply, FFT, convolution, sorting, and more
- **Invariant Engine**: 10 machine-checkable invariants with structured diagnostics
- **Recursive Controller**: Bounded recursion with explicit termination conditions
- **Mythos Engine**: Candidate generation and evaluation for architecture exploration
- **Force Mode**: Controlled stress testing with bounded resource consumption
- **Full Reproducibility**: Every experiment is reproducible from explicit seed
- **Complete Test Suite**: Using MATLAB's testing framework
- **Dual Licensing**: BSD-3-Clause OR GPL-1.0

## Architecture

The framework implements a complete execution pipeline:

```
CYCLE ALLOCATION
    ↓
CYCLE LEDGER
    ↓
WORK QUEUES
    ↓
SCHEDULER
    ↓
CYCLE STEALING
    ↓
COMPUTATIONAL KERNELS
    ↓
INVARIANT ENGINE
    ↓
RECURSIVE CONTROLLER
    ↓
MYTHOS CANDIDATE GENERATION
    ↓
CANDIDATE EVALUATION
    ↓
EXPERIMENT REGISTRY
    ↓
STATISTICS
    ↓
REPLAY
    ↓
REPORT
```

## Experiments

- Baseline FIFO scheduling
- Baseline balanced scheduler
- Random cycle stealing
- Bounded cycle stealing
- Priority-based stealing
- Recursive stealing
- Force mode (stress testing)
- Recursive Mythos exploration

## Documentation

- `docs/architecture.md` - System design and component interactions
- `docs/design.md` - Detailed design decisions
- `docs/invariants.md` - 10 machine-checkable invariants
- `docs/experiments.md` - Experiment design and methodology
- `docs/reproducibility.md` - Reproduction and determinism
- `docs/mythos.md` - Mythos candidate exploration
- `docs/licensing.md` - Licensing structure

## Repository Statistics

- 10,000+ lines of substantive MATLAB code
- 100+ MATLAB functions
- Comprehensive test suite
- Full CI/CD validation

## Testing

All tests use MATLAB's testing framework:

```matlab
run_tests
```

Tests cover:
- Cycle accounting
- Ledger conservation
- Worker state
- Queue operations
- Scheduler decisions
- Stealing policies
- Kernel correctness
- Invariants
- Recursion
- Persistence and replay
- Determinism
- Failure injection

## License

Dual-licensed under:
- **BSD-3-Clause** (`LICENSE.BSD-3-CLAUSE`)
- **GNU GPL v1.0** (`LICENSE.GPL-1.0`)

You may use this software under either license at your option.

## Version

v0.1.0 — Initial implementation

## Citation

If you use this framework, please cite:

```bibtex
@software{matlab_cycle_mythos_2026,
  title={MATLAB Cycle-Stealing and Recursive Mythos Framework},
  author={SNAPKITTY Research},
  year={2026},
  url={https://github.com/SNAPKITTYWEST/matlab-cycle-mythos}
}
```
