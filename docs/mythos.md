# Mythos Engine - Candidate Exploration

## Overview

The Mythos Engine implements automated exploration of the architecture space through candidate generation, evaluation, and recursive refinement. It searches for optimal scheduling and stealing strategies for given workloads.

## Core Concepts

### Candidate

A candidate represents a complete configuration:

```matlab
candidate = struct();
candidate.schedulerType = 'balanced';
candidate.stealingPolicy = 'priority';
candidate.workerCount = 8;
candidate.stealThreshold = 0.2;
candidate.stealingProbability = 0.1;
candidate.maxStealersPerRound = 4;
```

### Search Space

The search space consists of:

**Scheduler Types**:
- FIFO - Simple first-come, first-served
- Balanced - Load-balanced across workers
- Priority - Priority-queue based scheduling

**Stealing Policies**:
- None - No cycle stealing
- Random - Probabilistic stealing
- Bounded - Threshold-based stealing
- Priority - Priority-weighted stealing
- Recursive - Recursive rebalancing

**Worker Counts**: 2, 4, 8, 16, 32

**Steal Thresholds**: 0.1, 0.2, 0.3, 0.4, 0.5

**Stealing Probabilities**: 0.05, 0.1, 0.2, 0.3

Total combinations: 3 × 5 × 5 × 5 × 4 = 1,500 candidates

### Generation Strategy

Candidates are generated deterministically using a round-robin approach:

```matlab
candidates = mythos.generateCandidates(config, seed, 16);
```

**Property**: Same seed → same candidate sequence (reproducible)

### Evaluation Metric

Each candidate is evaluated on a scoring function:

```
score = throughput / (1 + overhead)

where:
  throughput = tasks_completed
  overhead = (steals / 100) + (cycles / 1e7)
```

**Interpretation**:
- Higher score is better
- Balances throughput gain with overhead cost
- Weights stealing operations and cycle usage

## Candidate Generation

### Deterministic Generation

```matlab
candidates = mythos.generateCandidates(config, seed, count);
```

**Parameters**:
- `config` - Base configuration
- `seed` - RNG seed for determinism
- `count` - Number of candidates to generate

**Returns**: Cell array of candidate configurations

**Properties**:
- Same seed produces same sequence
- Candidates cover search space systematically
- Duplicate-free (each candidate unique)

### Generation Algorithm

```
for i = 1 to count:
    scheduler = SCHEDULER_TYPES[(i-1) % num_schedulers]
    stealing = STEALING_POLICIES[(i-1) % num_policies]
    workers = WORKER_COUNTS[(i-1) % num_worker_counts]
    threshold = THRESHOLDS[(i-1) % num_thresholds]
    
    create candidate(scheduler, stealing, workers, threshold)
    assign unique candidateId
```

## Candidate Evaluation

### Evaluation Function

```matlab
[score, details] = mythos.evaluateCandidate(candidate, reps);
```

**Parameters**:
- `candidate` - Candidate configuration
- `reps` - Number of evaluation repetitions (default: 3)

**Returns**:
- `score` - Numerical score (higher is better)
- `details` - Detailed metrics structure

**Execution**:
```
for rep = 1 to reps:
    run_experiment(candidate with seed offset)
    record metrics (tasks, cycles, steals)
    check invariants

aggregate metrics across reps
compute score = mean_tasks / (1 + overhead)
```

### Scoring Function

The scoring function balances multiple objectives:

**Objective 1: Maximize Throughput**
```
throughput = tasks_completed
```

**Objective 2: Minimize Overhead**
```
overhead = (steals / scaling_factor) + (cycles / scaling_factor)
```

**Combined Score**:
```
score = throughput / (1 + overhead)
```

**Invariant Requirement**:
- If any invariant fails: score = 0 (invalid candidate)
- Only valid candidates scored

### Mutation Strategy

Candidates can be mutated to create variations:

```matlab
[mutated, distance] = mythos.mutateCandidate(candidate, mutation_rate);
```

**Mutation Operations**:
1. Flip scheduler type (10% probability)
2. Change stealing policy (20% probability)
3. Adjust worker count ±1 (15% probability)
4. Adjust thresholds ±0.1 (15% probability)

**Distance Metric**:
```
distance = hamming_distance(original, mutated)
```

## Recursive Exploration

### Tree Structure

Mythos organizes exploration as a recursive tree:

```
Root Candidate
├─ Level 1 (4 children)
│  ├─ Level 2 (4 children each)
│  │  └─ Level 3 (4 children each)
│  └─ ...
└─ ...
```

### Node Creation

```matlab
node = recursion.createNode(nodeId, parentId, depth, config, candidate);
```

**Node Properties**:
- `nodeId` - Unique identifier
- `parentId` - Parent node (0 if root)
- `depth` - Distance from root (0 = root)
- `config` - Configuration to use
- `candidate` - Candidate configuration
- `score` - Evaluation score
- `cycleBudget` - Cycles allocated (halved per level)

### Node Expansion

```matlab
[node, children] = recursion.expandNode(node, config, base_config);
```

**Process**:
1. Check depth limit (≤ maxRecursionDepth)
2. Check cycle budget remaining
3. Generate child candidates
4. Evaluate each child
5. Create child nodes
6. Return expanded node with children

**Termination Conditions**:
- Maximum depth reached
- Cycle budget exhausted
- Maximum nodes created
- No improvement in children

### Tree Traversal

**Breadth-First Search (BFS)**:
```
queue = [root]
while queue not empty:
    node = dequeue()
    if should_expand(node):
        children = expand(node)
        enqueue(children)
```

**Depth-First Search (DFS)**:
```
function dfs(node):
    if should_expand(node):
        children = expand(node)
        for each child:
            dfs(child)
```

## Running Mythos Exploration

### Basic Usage

```matlab
config = defaultConfig();
config.recursionEnabled = true;
config.mythosEnabled = true;
config.maxRecursionDepth = 3;
config.candidateCount = 16;

result = run_experiment('recursive_mythos');
```

### Advanced Configuration

```matlab
config.mythosEnabled = true;
config.candidateCount = 32;        % More candidates
config.evaluationReps = 5;         % More evaluation reps
config.maxRecursionDepth = 4;      % Deeper tree
config.maxTotalNodes = 200;        % More nodes
config.recursionCycleBudget = 1e8; % More cycles for exploration
config.mutationRate = 0.15;        % More mutation
```

### Analysis of Results

```matlab
result = run_experiment('recursive_mythos');

% Best candidate
[best_score, best_idx] = max(result.mythos.scores);
best_candidate = result.mythos.candidates{best_idx};

fprintf('Best candidate: %s\n', best_candidate.candidateId);
fprintf('Score: %.2f\n', best_score);
fprintf('Config: %s policy, %d workers\n', ...
    best_candidate.stealingPolicy, best_candidate.workerCount);

% Top 3
[sorted_scores, indices] = sort(result.mythos.scores, 'descend');
for i = 1:3
    cand = result.mythos.candidates{indices(i)};
    fprintf('%d. %s (score: %.2f)\n', i, cand.candidateId, sorted_scores(i));
end
```

## Candidate Diversity

### Diversity Metrics

**Hamming Distance**:
```
distance = sum(config1 != config2)
```

**Euclidean Distance** (continuous parameters):
```
distance = sqrt(sum((config1_params - config2_params)^2))
```

### Maintaining Diversity

To prevent converging to local optima:

```matlab
% Enforce minimum diversity
diversity_threshold = 0.3;
for each new_candidate:
    for each existing_candidate:
        distance = candidateDistance(new_candidate, existing_candidate);
        if distance < diversity_threshold:
            reject new_candidate
```

## Candidate Fingerprinting

```matlab
fingerprint = mythos.candidateFingerprint(candidate);
```

**Fingerprint Elements**:
- Scheduler type (1 byte)
- Stealing policy (1 byte)
- Worker count (1 byte)
- Thresholds hash (1 byte)

**Use Cases**:
- Detect duplicate candidates
- Create reproducible identifiers
- Enable candidate tracking

## Performance Characteristics

### Search Coverage

**Breadth-First Search**:
- Coverage: ~90% of space at depth 3
- Time: O(3^3 × eval_time) = ~27 evaluations
- Memory: O(3^3) = ~27 nodes

**Depth-First Search**:
- Coverage: Depends on early termination
- Time: O(3^depth × eval_time)
- Memory: O(depth) (stack-based)

### Cycle Budget Scaling

```
Level 0 (root):   budget = 1e8 / 1   = 1e8 cycles
Level 1:          budget = 1e8 / 2   = 5e7 cycles (per child)
Level 2:          budget = 1e8 / 4   = 2.5e7 cycles (per child)
Level 3:          budget = 1e8 / 8   = 1.25e7 cycles (per child)
```

## Practical Usage Patterns

### Quick Exploration

```matlab
config = defaultConfig();
config.recursionEnabled = true;
config.maxRecursionDepth = 1;      % Just one level
config.candidateCount = 4;         % Few candidates

result = run_experiment('recursive_mythos');
best = result.mythos.bestCandidate;
```

### Thorough Search

```matlab
config = defaultConfig();
config.recursionEnabled = true;
config.maxRecursionDepth = 4;      % Deep search
config.candidateCount = 32;        % Many candidates
config.evaluationReps = 5;         % Robust evaluation
config.recursionCycleBudget = 1e9; % Generous budget

result = run_experiment('recursive_mythos');
```

### Production Tuning

```matlab
% Find optimal config for specific workload
config = defaultConfig();
config.kernelType = 'matrix_multiply';
config.kernelSize = 512;           % Production-like size

config.recursionEnabled = true;
config.maxRecursionDepth = 2;
config.candidateCount = 16;

result = run_experiment('recursive_mythos');
best_config = result.mythos.bestCandidate;

% Use best_config in production
production_config = best_config;
production_result = runWithConfig(production_config);
```

## Troubleshooting

### Mythos Not Improving

**Symptom**: All candidates have similar scores

**Causes**:
- Search space too small
- Evaluation function insensitive
- Workload doesn't benefit from stealing

**Solutions**:
- Increase `candidateCount`
- Adjust scoring function weights
- Test with different workload sizes

### Cycle Budget Exhausted

**Symptom**: "Recursion budget exhausted" error

**Causes**:
- Too many candidates
- Too deep recursion
- Too many evaluation reps

**Solutions**:
- Reduce `maxRecursionDepth` 
- Reduce `candidateCount`
- Reduce `evaluationReps`
- Increase `recursionCycleBudget`

### Slow Convergence

**Symptom**: Exploration takes hours

**Causes**:
- Large kernel sizes
- Many evaluation repetitions
- Deep recursion tree

**Solutions**:
- Use smaller kernel size for exploration
- Reduce evaluation reps during search
- Limit recursion depth
- Use BFS instead of DFS

## Advanced Topics

### Custom Scoring Functions

Replace default score with custom function:

```matlab
% In evaluateCandidate.m
% Modify scoring to weight latency:
score = (tasks / latency) / (1 + overhead);
```

### Candidate Filtering

Pre-filter candidates based on criteria:

```matlab
% Only test policies with good baseline scores
if result_baseline.score > threshold
    evaluate_recursive(candidate)
end
```

### Parallel Evaluation

Evaluate multiple candidates in parallel (advanced):

```matlab
parfor c = 1:length(candidates)
    scores(c) = evaluateCandidate(candidates{c}, 1);
end
```

Note: Requires MATLAB Parallel Computing Toolbox
