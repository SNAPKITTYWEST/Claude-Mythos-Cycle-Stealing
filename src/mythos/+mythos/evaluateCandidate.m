% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [score, details] = evaluateCandidate(candidate, reps)
    % Evaluate a candidate configuration
    % Returns a score and detailed metrics

    arguments
        candidate struct
        reps (1,1) {mustBePositive} = 3
    end

    details = struct();
    details.candidateId = candidate.candidateId;
    details.config = candidate;
    details.repetitions = reps;

    % Run experiment multiple times with different seeds
    results = {};
    tasks = [];
    cycles = [];
    steals = [];
    invariant_passes = [];

    for r = 1:reps
        % Modify seed for this repetition
        config_rep = candidate;
        config_rep.seed = candidate.seed + r - 1;

        try
            % Run experiment
            result = run_experiment(candidate.experimentType);
            results{r} = result;

            tasks(r) = result.statistics.totalTasksCompleted;
            cycles(r) = result.statistics.totalCyclesConsumed;
            steals(r) = result.statistics.totalStealOperations;
            invariant_passes(r) = result.invariantPass;

        catch ME
            % Failed run
            results{r} = [];
            tasks(r) = 0;
            cycles(r) = 0;
            steals(r) = 0;
            invariant_passes(r) = false;
        end
    end

    % Compute aggregate metrics
    details.results = results;
    details.meanTasks = mean(tasks);
    details.stdTasks = std(tasks);
    details.meanCycles = mean(cycles);
    details.meanSteals = mean(steals);
    details.invariantPassRate = mean(invariant_passes);

    % === Scoring Function ===
    % Maximize: throughput (tasks completed)
    % Minimize: overhead (steals + cycles)
    % Require: all invariants pass

    if all(invariant_passes) == 0
        % Any failed invariant check → low score
        score = 0;
        details.scoreReason = 'Invariant violation';
        return;
    end

    % Score = tasks / (1 + overhead)
    % where overhead = (steals + cycles relative cost)
    overhead = (mean(steals) / 100) + (mean(cycles) / 1e7);
    score = details.meanTasks / (1 + overhead);

    details.overhead = overhead;
    details.score = score;
    details.scoreReason = 'Valid candidate';

end
