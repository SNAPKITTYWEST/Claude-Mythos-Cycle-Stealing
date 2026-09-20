# MATLAB Cycle-Stealing & Recursive Mythos Framework

MATLAB code for exploring cycle-stealing schedulers, cycle accounting, recursive control, and Mythos candidate generation. The repository also contains 32 research runtime modules covering geometric algebra, finite fields, quantum models, verification, and related experiments.

## Repository layout

| Path | Contents |
| --- | --- |
| [src/](src/) | MATLAB packages for the scheduler, ledger, stealing policies, kernels, invariants, recursion, and candidate exploration |
| [runtime/](runtime/) | Research modules grouped by the A1-H4 identifiers |
| [config/](config/) | Default experiment configuration |
| [tests/](tests/) | Scheduler, ledger, kernel, replay, and research-module tests |
| [verification/](verification/) | Findings registry, instrumentation, verification gates, and counterexample searches |
| [ci/](ci/) | MATLAB repository audit entry point |
| [docs/](docs/README.md) | Documentation index and repository map |
| [docs/guides/](docs/guides/) | Quick start, development guide, and extended framework documentation |
| [docs/reports/](docs/reports/) | Implementation reports, manifests, and deployment checklists |
| [docs/releases/](docs/releases/) | Release notes |

The four `run_*.m` entry points remain at the repository root. MATLAB source, package directories, configuration, and tests retain their existing paths.

## Getting started

Clone the repository and open its root directory in MATLAB:

```sh
git clone https://github.com/SNAPKITTYWEST/Claude-Mythos-Cycle-Stealing.git
cd Claude-Mythos-Cycle-Stealing
```

Add the source and configuration directories to the MATLAB path:

```matlab
addpath(genpath('src'));
addpath('config');
addpath('runtime');
addpath(genpath('verification'));
```

Experiment task generation uses `poissrnd` from the Statistics and Machine Learning Toolbox.

| Entry point | Purpose |
| --- | --- |
| `run_experiment('baseline')` | Run one experiment configuration |
| `run_all` | Run the six scheduler/stealing experiments listed below |
| `run_benchmarks` | Run the benchmark driver |
| `run_tests` | Run the MATLAB test-suite entry point |

See the [quick-start guide](docs/guides/QUICKSTART.md) and [user guide](docs/user-guide.md) for further examples.

## Experiments and configuration

[run_experiment.m](run_experiment.m) accepts these experiment names:

| Name | Configuration selected |
| --- | --- |
| `baseline` | Balanced scheduling, stealing disabled |
| `random_stealing` | Random stealing policy |
| `bounded_stealing` | Threshold-based stealing policy |
| `priority_stealing` | Priority stealing policy |
| `recursive_stealing` | Recursive stealing policy |
| `force_mode` | Force-mode settings with random stealing |
| `recursive_mythos` | Recursion and Mythos flags enabled |

[run_all.m](run_all.m) selects the first six entries. Defaults live in [config/defaultConfig.m](config/defaultConfig.m), including the seed, worker count, cycle budget, scheduling policy, recursion limits, and output paths. Saved experiment results use the configured `resultsDir`, which defaults to `./results`.

## Source packages

| Package | Responsibilities |
| --- | --- |
| [ledger](src/ledger/) | Create, allocate, consume, transfer, return, snapshot, validate, and replay cycle balances |
| [scheduler](src/scheduler/) | Enqueue/dequeue tasks, inspect queues, assign priorities, and balance work |
| [stealing](src/stealing/) | Random, bounded, priority, and recursive cycle-stealing policies |
| [execution](src/execution/) | Worker state creation |
| [kernels](src/kernels/) | Matrix multiplication, FFT, convolution, sorting, reduction, and kernel benchmarking |
| [invariant](src/invariant/) | Cycle, balance, queue, latency, recursion, and replay checks |
| [recursion](src/recursion/) | Recursion-node creation and expansion |
| [mythos](src/mythos/) | Candidate generation and evaluation |
| [statistics](src/statistics/) | Aggregate experiment runs |
| [utilities](src/utilities/) | Seed handling, state hashing, configuration validation, and repository auditing |

## Research modules

The [runtime directory](runtime/) uses stable identifiers shared with the [findings registry](verification/NOVEL_FINDINGS_REGISTRY.json) and module tests.

| Group | Modules |
| --- | --- |
| A1-A4 | Cycle-stealing MoE, three-level hierarchy, quantum decoder, PUF/PCR key derivation |
| B1-B5 | Clifford rotors, GKA/HSP reduction, Hamiltonian evolution, cross-ratio commitment, resultant signatures |
| C1-C4 | GF(256) log gauge, AES trail search, terminal analysis, discovery analysis |
| D1-D4 | E7 symmetries, I4 homogeneity, QKD/I4 chain, Boolean identities |
| E1-E4 | QLG/SLA/QRA, epistemic witnesses, JWT evolution, quantum approximation limit |
| F1-F4 | Proof DAG, boot gate, Taylor TQC, Watson identity |
| G1-G3 | AEAD commitment, invocation limits, SHA3 policy |
| H1-H4 | Mobius obligations, I4 full state, QKD chain, MixColumns linearity |

[verification/](verification/) contains the instrumentation API, epistemic status machine, SAS comparison bridge, and H1-H4 counterexample harnesses.

## Documentation

- [Documentation index and file relocation map](docs/README.md)
- [Architecture](docs/architecture.md) and [design](docs/design.md)
- [Experiments](docs/experiments.md) and [reproducibility](docs/reproducibility.md)
- [Invariants](docs/invariants.md) and [ledger mathematics](src/ledger/LEDGER_MATHEMATICS.md)
- [Mythos exploration](docs/mythos.md) and [reference](docs/reference.md)
- [Development guide](docs/guides/DEVELOPMENT.md)
- [Extended framework guide](docs/guides/README_UNIFIED.md)
- [Changelog](CHANGELOG.md) and [version 2 release notes](docs/releases/RELEASE_NOTES_V2.md)

## License and citation

Dual-licensed under [BSD-3-Clause](LICENSE.BSD-3-CLAUSE) or [GNU GPL v1.0](LICENSE.GPL-1.0), at your option. See [licensing](docs/licensing.md) for details and [CITATION.cff](CITATION.cff) for citation metadata.
