# Changelog

All notable changes to the MATLAB Cycle-Stealing and Recursive Mythos Framework.

## [0.1.0] - 2026-09-19

### Added

#### Core Infrastructure
- Complete cycle ledger system with conservation invariant (I1)
- Deterministic scheduler with FIFO and balanced modes
- Five cycle-stealing policies: random, bounded, priority, recursive, none
- Computational kernels: matrix multiply, FFT, convolution, sort, reduction
- 10 machine-checkable invariants with continuous validation
- Recursive exploration engine with bounded tree traversal
- Mythos candidate generation and evaluation system
- Complete event logging and replay verification

#### Cycle Management
- Cycle allocation with exact accounting
- Cycle consumption with non-negativity guarantee (I2)
- Cycle stealing with conservation preservation
- Cycle return to available pool
- Ledger validation and integrity checking

#### Scheduling
- FIFO queue operations (enqueue, dequeue, peek)
- Load-balanced queue operations
- Queue integrity checking (I3)
- Priority assignment and task prioritization
- Automatic load rebalancing

#### Cycle Stealing
- Random stealing with probabilistic selection
- Bounded stealing with threshold-based activation
- Priority stealing with smart donor/recipient selection
- Recursive stealing with depth limiting
- Stealing policy factory with pluggable architecture

#### Computational Kernels
- Matrix multiplication (configurable size and reps)
- Fast Fourier Transform (1D FFT)
- Signal convolution
- Array sorting
- Reduction operations (sum)
- Deterministic input generation
- Cycle estimation and metadata

#### Invariant Validation
- **I1**: Cycle Conservation (totalCycles = allocated + available)
- **I2**: Nonnegative Balances (all worker cycles >= 0)
- **I3**: Queue Integrity (tasks in at most one queue)
- **I4**: Replay Consistency (same events = same final state)
- **I5**: Determinism (same seed = identical results)
- **I6**: Latency Bound (tasks complete within timeout)
- **I7**: Throughput Target (performance metrics)
- **I8**: Recursion Bound (depth and node limits)
- **I9**: Candidate Integrity (valid evaluation records)
- **I10**: Experiment Closure (complete result records)

#### Experiment Execution
- Baseline experiment (reference comparison)
- Random stealing experiment
- Bounded stealing experiment
- Priority stealing experiment
- Recursive stealing experiment
- Force mode experiment (stress testing)
- Recursive Mythos experiment (architecture search)
- Complete experiment registry with unique IDs
- Event-based execution with full instrumentation

#### Determinism and Reproducibility
- Deterministic RNG seeding (MT19937)
- Complete event logging (every state change)
- Event replay verification
- Configuration immutability
- Bit-exact reproducibility from seed + config
- Replay consistency checking (I4)
- Determinism testing suite

#### Recursive Exploration
- Recursive tree node creation and management
- Node expansion with candidate generation
- Depth-limited recursion (bounded I8)
- Node count limiting
- Cycle budget allocation per level
- Breadth-first and depth-first traversal

#### Mythos Engine
- Deterministic candidate generation
- Candidate configuration space
- Candidate evaluation with scoring
- Candidate mutation
- Candidate diversity metrics
- Fingerprinting for reproducibility
- Multi-level recursive exploration

#### Statistics and Analysis
- Task completion metrics
- Cycle consumption tracking
- Cycle stealing statistics
- Load balance metrics
- Worker utilization analysis
- Latency statistics
- Throughput computation
- Percentile calculations
- Confidence interval estimation
- Multi-run aggregation

#### Testing Framework
- Complete unit test suite (MATLAB testing framework)
- TestLedger - 10+ tests for cycle accounting
- TestScheduler - 9+ tests for queue operations
- TestStealing - 10+ tests for all policies
- TestKernels - 7+ tests for workloads
- TestInvariant - 10+ tests for invariants
- TestDeterminism - 10+ tests for reproducibility
- TestReplay - 10+ tests for replay verification
- TestPersistence - 9+ tests for save/load
- TestRecursion - Recursion bounding
- All tests use MATLAB unittest framework

#### CI/CD Pipeline
- Repository structure audit
- MATLAB-only verification
- Python removal audit (forbidden pattern detection)
- Line count audit (>= 10,000 lines)
- Function count audit (>= 100 functions)
- License audit (dual license verification)
- Invariant coverage audit

#### Dual Licensing
- BSD-3-Clause license option
- GPL-1.0 license option
- Clear license selection mechanism
- License headers in source files
- License audit in CI

#### Documentation
- README with quick start
- User guide with common tasks
- API reference with all functions
- Architecture document with system design
- Design decisions document
- Invariants specification with detailed examples
- Experiments methodology document
- Reproducibility guide with verification methods
- Mythos engine documentation
- Reference manual with all APIs
- Implementation notes with technical details
- Development guide for contributors
- Quick start guide for immediate use
- Licensing documentation
- Changelog (this file)

#### Utilities
- Configuration validation
- Deterministic seed initialization
- State hashing for reproducibility
- Python removal auditing
- Global ledger management

#### Persistence
- Experiment result saving (.mat format)
- Configuration serialization
- Ledger state persistence
- Event log export
- Trace file generation
- Multi-experiment archive creation

#### Examples and Demonstrations
- run_experiment.m - Single experiment execution
- run_all.m - Comparative benchmark
- run_tests.m - Test suite runner
- run_benchmarks.m - Comprehensive benchmarking
- run_ci.m - CI/CD pipeline

### Technical Specifications

- **Language**: MATLAB only (no external dependencies)
- **Framework Type**: Deterministic scheduling simulator
- **Architecture**: Event-based with invariant validation
- **Threading**: Single-threaded (MATLAB limitation)
- **Scalability**: Workers 2-32+, cycles 1M-1B+
- **Performance**: O(workers) per step
- **Memory**: 10-100 MB typical
- **Reproducibility**: Bit-exact from seed and config

### Quality Metrics

- 10,000+ lines of substantive code
- 100+ MATLAB functions
- 50+ comprehensive tests
- 10 machine-checkable invariants
- Dual licensing
- Full documentation
- Complete test coverage
- CI/CD validation

### Known Limitations

- Single-threaded (MATLAB)
- Event log memory (large experiments need >100MB)
- Worker count practical limit ~32
- Kernel implementations simplified (not actual hardware)

### Future Roadmap

- v0.2.0: Visualization enhancements, GUI
- v0.3.0: Genetic algorithm Mythos search
- v0.4.0: Hardware integration
- v1.0.0: Parallel Computing Toolbox support

### Contributors

- SNAPKITTY Research Team

### Acknowledgments

- Cilk work-stealing scheduler
- Deterministic replay verification
- Invariant-based testing
- MATLAB Unit Testing Framework

### Support

- GitHub Issues: Bug reports and feature requests
- Documentation: See docs/ directory
- Quick Start: See QUICKSTART.md
- Development: See DEVELOPMENT.md

### Citation

```bibtex
@software{matlab_cycle_mythos_2026,
  title={MATLAB Cycle-Stealing and Recursive Mythos Framework},
  author={SNAPKITTY Research},
  year={2026},
  url={https://github.com/SNAPKITTYWEST/matlab-cycle-mythos}
}
```

### License

Dual-licensed under:
- BSD-3-Clause (see LICENSE.BSD-3-CLAUSE)
- GPL-1.0 (see LICENSE.GPL-1.0)

Choose either license at your option.

---

## Version History

### 0.1.0 (2026-09-19)
Initial release with complete cycle-stealing framework, 10 invariants, full reproducibility, and comprehensive test suite.

---

**Framework Status**: Production Ready  
**Latest Version**: 0.1.0  
**Release Date**: 2026-09-19
