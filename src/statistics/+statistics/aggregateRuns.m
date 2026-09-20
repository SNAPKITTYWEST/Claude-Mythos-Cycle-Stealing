% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function aggregated = aggregateRuns(results_array)
    % Aggregate statistics across multiple experiment runs
    % Computes mean, variance, percentiles across runs

    arguments
        results_array (1,:) struct
    end

    aggregated = struct();
    aggregated.runCount = length(results_array);
    aggregated.timestamp = datetime('now');

    % Extract metrics from each run
    tasks_completed = [];
    cycles_consumed = [];
    steals = [];
    mean_latencies = [];
    throughputs = [];

    for i = 1:length(results_array)
        result = results_array(i);
        tasks_completed(i) = result.statistics.totalTasksCompleted;
        cycles_consumed(i) = result.statistics.totalCyclesConsumed;
        steals(i) = result.statistics.totalStealOperations;
        mean_latencies(i) = result.statistics.meanThroughput;
    end

    % === Task Completion Statistics ===
    aggregated.tasksCompleted.mean = mean(tasks_completed);
    aggregated.tasksCompleted.median = median(tasks_completed);
    aggregated.tasksCompleted.std = std(tasks_completed);
    aggregated.tasksCompleted.min = min(tasks_completed);
    aggregated.tasksCompleted.max = max(tasks_completed);
    aggregated.tasksCompleted.var = var(tasks_completed);

    % === Cycle Consumption Statistics ===
    aggregated.cyclesConsumed.mean = mean(cycles_consumed);
    aggregated.cyclesConsumed.median = median(cycles_consumed);
    aggregated.cyclesConsumed.std = std(cycles_consumed);
    aggregated.cyclesConsumed.min = min(cycles_consumed);
    aggregated.cyclesConsumed.max = max(cycles_consumed);

    % === Stealing Statistics ===
    aggregated.steals.mean = mean(steals);
    aggregated.steals.median = median(steals);
    aggregated.steals.std = std(steals);
    aggregated.steals.total = sum(steals);

    % === Percentiles ===
    percentiles = [10 25 50 75 90 95 99];
    aggregated.tasksCompleted.percentiles = prctile(tasks_completed, percentiles);
    aggregated.tasksCompleted.percentileValues = percentiles;

    aggregated.cyclesConsumed.percentiles = prctile(cycles_consumed, percentiles);

    % === Confidence Intervals (95%) ===
    se_tasks = std(tasks_completed) / sqrt(length(tasks_completed));
    aggregated.tasksCompleted.ci95 = [mean(tasks_completed) - 1.96*se_tasks, ...
                                       mean(tasks_completed) + 1.96*se_tasks];

    se_cycles = std(cycles_consumed) / sqrt(length(cycles_consumed));
    aggregated.cyclesConsumed.ci95 = [mean(cycles_consumed) - 1.96*se_cycles, ...
                                       mean(cycles_consumed) + 1.96*se_cycles];

end
