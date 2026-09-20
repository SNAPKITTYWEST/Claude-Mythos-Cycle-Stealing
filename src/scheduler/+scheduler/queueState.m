% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function state = queueState(queues)
    % Get complete state snapshot of all queues

    state = struct();
    state.type = queues.type;
    state.timestamp = datetime('now');
    state.totalWorkers = length(queues.workerQueues);
    state.totalEnqueued = queues.totalEnqueued;
    state.totalDequeued = queues.totalDequeued;
    state.totalPending = queues.totalEnqueued - queues.totalDequeued;

    % Per-worker statistics
    depths = [];
    for i = 1:length(queues.workerQueues)
        depths(i) = queues.workerQueues(i).taskCount;
    end

    state.queueDepths = depths;
    state.meanDepth = mean(depths);
    state.medianDepth = median(depths);
    state.minDepth = min(depths);
    state.maxDepth = max(depths);
    state.stdDevDepth = std(depths);

    % Imbalance metric
    state.depthImbalance = max(0, max(depths) - min(depths));
    state.depthVariance = var(depths);

    % Event statistics
    state.eventCount = queues.eventCount;
    state.eventLogFull = (queues.eventCount >= queues.maxEvents);

end
