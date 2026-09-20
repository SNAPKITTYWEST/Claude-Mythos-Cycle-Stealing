# Development Guide

This guide covers developing, extending, and maintaining the MATLAB Cycle-Stealing Framework.

## Setting Up Development Environment

### Prerequisites

- MATLAB R2019a or later
- Git
- Text editor (VS Code recommended)

### Clone and Setup

```bash
git clone https://github.com/SNAPKITTYWEST/matlab-cycle-mythos.git
cd matlab-cycle-mythos
```

### Add to MATLAB Path

```matlab
addpath(genpath('/path/to/matlab-cycle-mythos'));
savepath; % Optional: save for future sessions
```

### Verify Installation

```matlab
% Run tests
run_tests();

% Run benchmarks
run_benchmarks();

% Run CI
[pass, results] = run_ci();

% All should complete without errors
```

## Development Workflow

### 1. Create Feature Branch

```bash
git checkout -b feature/my-feature
```

### 2. Make Changes

Develop in your feature branch:

```matlab
% Edit files in src/ or tests/
% Follow naming conventions
% Add tests for new functionality
```

### 3. Run Tests

```matlab
% Unit tests
run_tests();

% Specific test class
run(matlab.unittest.TestLoader().loadTestsFromTestCase(?TestLedger));

% Benchmarks
run_benchmarks();

% CI checks
[pass, results] = run_ci();
```

### 4. Verify Determinism

```matlab
% Test reproducibility
config = defaultConfig();
config.seed = 12345;

result1 = run_experiment('baseline');
result2 = run_experiment('baseline');

assert(result1.statistics.totalTasksCompleted == ...
       result2.statistics.totalTasksCompleted);
```

### 5. Check Invariants

```matlab
result = run_experiment('baseline');

if ~result.invariantPass
    fprintf('ERROR: Invariants failed\n');
    return;
end
```

### 6. Commit and Push

```bash
git add src/...
git commit -m "Add feature: description"
git push origin feature/my-feature
```

### 7. Create Pull Request

- Describe changes clearly
- Link related issues
- Ensure CI passes

## Code Style Guide

### Function Naming

```matlab
% Verbs first, then noun
allocate(...)       % OK
dequeue(...)        % OK
getQueueSize(...)   % OK
validateConfig(...) % OK

% Not:
% allocateCycles(...)  % Redundant with parameter types
% queueDequeue(...)    % Verb at end
```

### Variable Naming

```matlab
% camelCase for local variables
workerCount = 8;
stealThreshold = 0.2;
eventLog = [];

% UPPER_CASE for constants (rare in MATLAB)
MAX_WORKERS = 32;
MAX_RECURSION_DEPTH = 10;
```

### Comments

```matlab
% Minimal comments - code should be self-documenting
% Comments explain WHY, not WHAT

% NOT:
% i = i + 1; % Increment i

% YES:
% Save unprocessed event for next iteration
unprocessed_events(end+1) = event;
```

### Function Headers

```matlab
function [result, metadata] = myFunction(input1, input2)
    % Brief description of what function does
    % 
    % Longer description if needed for clarity
    % 
    % Input:
    %   input1 - Description
    %   input2 - Description
    %
    % Output:
    %   result - Description
    %   metadata - Description
```

### Line Length

- Maximum 100 characters (some flexibility for readability)
- Break long lines at logical points

## Testing

### Writing Unit Tests

```matlab
classdef TestMyFeature < matlab.unittest.TestCase

    properties
        config
    end

    methods(TestMethodSetup)
        function setup(testCase)
            addpath(genpath('../src'));
            testCase.config = defaultConfig();
        end
    end

    methods(Test)

        function testBasicFunctionality(testCase)
            % Test description
            result = myFunction(testCase.config);
            testCase.verifyNotEmpty(result);
            testCase.verifyTrue(condition);
        end

        function testInvariant(testCase)
            % Verify invariant maintained
            [pass, diag] = invariant.myInvariant(state);
            testCase.verifyTrue(pass);
        end

        function testEdgeCase(testCase)
            % Test boundary conditions
            result = myFunction([], []);
            testCase.verifyEmpty(result);
        end

    end

end
```

### Running Tests

```matlab
% All tests
run_tests();

% Specific class
run(matlab.unittest.TestLoader().loadTestsFromTestCase(?TestMyFeature));

% With verbosity
suite = matlab.unittest.TestSuite.fromFolder('./tests');
runner = matlab.unittest.TextTestRunner('Verbosity', ...
    matlab.unittest.Verbosity.Verbose);
result = runner.run(suite);
```

### Test Coverage

Aim for:
- Unit test: All functions tested
- Integration test: Major workflows tested
- System test: End-to-end experiments tested
- Edge cases: Boundary conditions tested
- Error handling: Invalid inputs tested

## Adding Features

### Add New Stealing Policy

**Step 1**: Create function

```matlab
% File: src/stealing/+stealing/myPolicy.m

function [ledger, steal_events] = myPolicy(ledger, config)
    % Your implementation
    steal_events = [];
    % ... stealing logic ...
end
```

**Step 2**: Register in factory

```matlab
% File: src/stealing/+stealing/policyFactory.m

% Add to switch statement:
case 'my_policy'
    [ledger, steal_events] = stealing.myPolicy(ledger, config);
```

**Step 3**: Add test

```matlab
% File: tests/TestStealing.m

function testMyPolicy(testCase)
    config = defaultConfig();
    config.stealingPolicy = 'my_policy';
    
    [ledger_result, steal_events] = stealing.myPolicy(...
        testCase.ledger, config);
    
    % Verify invariants
    [pass, ~] = invariant.cycleConservation(ledger_result);
    testCase.verifyTrue(pass);
end
```

**Step 4**: Document

Add entry to `docs/reference.md`:

```markdown
### `stealing.myPolicy()`

My stealing policy description.

**Syntax**:
```matlab
[ledger, steal_events] = stealing.myPolicy(ledger, config);
```
```

**Step 5**: Test

```matlab
config = defaultConfig();
config.stealingPolicy = 'my_policy';

result = run_experiment('baseline'); % Will use your policy

% Verify correctness
assert(result.invariantPass);
fprintf('New policy working!\n');
```

### Add New Invariant

**Step 1**: Create invariant check

```matlab
% File: src/invariant/+invariant/myInvariant.m

function [pass, diagnostic] = myInvariant(state)
    diagnostic = struct();
    diagnostic.invariant = 'I11_MyInvariant';
    
    % Check condition
    pass = (condition_true);
    
    diagnostic.pass = pass;
    if ~pass
        diagnostic.message = sprintf('Violation: %s', reason);
    end
end
```

**Step 2**: Register in assertion

```matlab
% File: src/invariant/+invariant/assertInvariant.m

% Add check:
[results.I11_pass, results.I11_diag] = invariant.myInvariant(state);
all_pass = all_pass && results.I11_pass;
```

**Step 3**: Add test

```matlab
function testMyInvariant(testCase)
    [pass, diag] = invariant.myInvariant(valid_state);
    testCase.verifyTrue(pass);
    
    invalid_state = ...;
    [pass, diag] = invariant.myInvariant(invalid_state);
    testCase.verifyFalse(pass);
end
```

**Step 4**: Document

Add to `docs/invariants.md`

### Add New Experiment Type

**Step 1**: Add configuration variant

```matlab
% File: config/customConfig.m

function config = customConfig()
    config = defaultConfig();
    config.experimentType = 'my_experiment';
    config.workerCount = 16;
    config.stealingPolicy = 'my_policy';
end
```

**Step 2**: Add experiment script

```matlab
% File: experiments/runMyExperiment.m

function result = runMyExperiment()
    config = customConfig();
    result = run_experiment_with_config(config);
end
```

**Step 3**: Test

```matlab
result = runMyExperiment();
fprintf('Experiment complete: %d tasks\n', ...
    result.statistics.totalTasksCompleted);
```

## Bug Reporting

When reporting bugs:

1. **Minimal reproduction**
   ```matlab
   % Smallest code that shows bug
   config = defaultConfig();
   config.seed = 12345;
   result = run_experiment('baseline');
   % Expected: Pass invariants
   % Actual: Invariant I2 fails
   ```

2. **Environment**
   ```matlab
   version('-release')  % MATLAB version
   computer             % Platform
   ```

3. **Expected vs actual**
   - What should happen
   - What actually happens
   - Why it's wrong

4. **Reproducibility**
   - Can you reproduce consistently?
   - Only with specific config?
   - Only with specific seed?

## Performance Profiling

### Identify Bottlenecks

```matlab
% Profile main loop
profile on

result = run_experiment('baseline');

profile off
profview  % Opens profiler GUI
```

### Measure Execution Time

```matlab
tic;
result = run_experiment('baseline');
elapsed = toc;

fprintf('Execution time: %.2f seconds\n', elapsed);
```

### Memory Usage

```matlab
% Check memory before
mem_before = memory();

result = run_experiment('baseline');

mem_after = memory();
mem_used = (mem_after.MemUsedMATLAB - mem_before.MemUsedMATLAB) / 1e6;

fprintf('Memory used: %.1f MB\n', mem_used);
```

## Documentation

### Updating Documentation

1. **API Reference**: `docs/reference.md`
   - Function signatures
   - Parameters and returns
   - Example usage

2. **User Guide**: `docs/user-guide.md`
   - Common tasks
   - Workflows
   - Troubleshooting

3. **Architecture**: `docs/architecture.md`
   - System design
   - Component interactions
   - Data flow

4. **Design**: `docs/design.md`
   - Design decisions
   - Rationale
   - Tradeoffs

### Building Docs

```bash
# Documentation is markdown in docs/
# Open in any markdown viewer or:

# Preview in MATLAB
edit('docs/architecture.md')  % Opens in editor
```

## Release Process

### Pre-Release Checklist

- [ ] All tests pass
- [ ] CI pipeline passes
- [ ] No uncommitted changes
- [ ] Update version number
- [ ] Update CHANGELOG
- [ ] Review documentation
- [ ] Run benchmarks
- [ ] Verify determinism
- [ ] Check line count (>= 10,000)

### Version Numbering

Use semantic versioning: MAJOR.MINOR.PATCH

- **MAJOR**: Breaking changes
- **MINOR**: New features
- **PATCH**: Bug fixes

### Creating Release

```bash
git tag v0.2.0
git push origin v0.2.0

# On GitHub: Create release from tag
# Add changelog and notes
```

## Troubleshooting Development

### Test Failures

```matlab
% Run specific test for debugging
run(matlab.unittest.TestLoader().loadTestsFromTestCase(?TestMyFeature));

% Use debugger
dbstop in myFunction
result = run_experiment('baseline');
dbcont
```

### Invariant Violations

```matlab
% Enable detailed diagnostics
config = defaultConfig();
config.validateInvariants = true;
config.failOnInvariantViolation = true;

result = run_experiment('baseline');
% Will error immediately on violation with diagnostics
```

### Performance Issues

```matlab
% Profile
profile on
result = run_experiment('baseline');
profile off
profview

% Identify slow functions
% Optimize bottlenecks
% Benchmark improvement
```

## Contributing Guidelines

1. Fork repository
2. Create feature branch (`feature/my-feature`)
3. Make changes
4. Add tests
5. Update documentation
6. Verify all tests pass
7. Commit with clear message
8. Push and create pull request

## Community

- Report bugs via GitHub Issues
- Discuss features in Discussions
- Contribute improvements via Pull Requests
- Share research and results

## Resources

- MATLAB Documentation: https://www.mathworks.com/help/matlab/
- Cilk Scheduler: https://en.wikipedia.org/wiki/Cilk
- Work Stealing: https://en.wikipedia.org/wiki/Work_stealing
- Deterministic Replay: https://en.wikipedia.org/wiki/Replay-based_debugging

---

**Framework Version**: 0.1.0  
**Last Updated**: 2026-09-19  
**Maintainer**: SNAPKITTY Research

For questions, open an issue on GitHub or contact maintainers.
