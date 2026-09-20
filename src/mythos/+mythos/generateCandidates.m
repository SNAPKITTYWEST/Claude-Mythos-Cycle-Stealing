% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function candidates = generateCandidates(config, seed, count)
    % Generate candidate configurations for Mythos exploration
    % Each candidate represents a potential scheduling/stealing strategy

    arguments
        config struct
        seed (1,1) uint64 {mustBePositive}
        count (1,1) {mustBePositive}
    end

    % Set RNG for deterministic generation
    rng_state = utils.deterministicSeed(seed);

    candidates = {};
    candidate_count = 0;

    % === Candidate Search Space ===
    scheduler_types = {'FIFO', 'balanced', 'priority'};
    stealing_policies = {'none', 'random', 'bounded', 'priority', 'recursive'};
    worker_counts = [2 4 8 16];
    steal_thresholds = [0.1 0.2 0.3 0.4 0.5];
    stealing_probs = [0.05 0.1 0.2 0.3];

    % Generate candidates (deterministically)
    scheduler_idx = 1;
    stealing_idx = 1;
    worker_idx = 1;
    threshold_idx = 1;
    prob_idx = 1;

    while candidate_count < count

        % Create candidate configuration
        candidate = config;

        % Assign parameters (round-robin through options)
        candidate.schedulerType = scheduler_types{scheduler_idx};
        candidate.stealingPolicy = stealing_policies{stealing_idx};
        candidate.workerCount = worker_counts{worker_idx};

        if strcmp(stealing_policies{stealing_idx}, 'bounded')
            candidate.stealThreshold = steal_thresholds{threshold_idx};
        else
            candidate.stealThreshold = 0.2; % Default
        end

        if strcmp(stealing_policies{stealing_idx}, 'random')
            candidate.stealingProbability = stealing_probs{prob_idx};
        else
            candidate.stealingProbability = 0.1; % Default
        end

        % Assign unique candidate ID
        candidate.candidateId = sprintf('cand_%03d_%s_%s_%d', ...
            candidate_count + 1, ...
            candidate.schedulerType, ...
            candidate.stealingPolicy, ...
            candidate.workerCount);

        candidate_count = candidate_count + 1;
        candidates{candidate_count} = candidate;

        % Advance to next combination (round-robin)
        scheduler_idx = mod(scheduler_idx, length(scheduler_types)) + 1;
        stealing_idx = mod(stealing_idx, length(stealing_policies)) + 1;
        worker_idx = mod(worker_idx, length(worker_counts)) + 1;
        threshold_idx = mod(threshold_idx, length(steal_thresholds)) + 1;
        prob_idx = mod(prob_idx, length(stealing_probs)) + 1;
    end

end
