% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [pass, diagnostic] = latencyBound(ledger, workers, config)
    % I6: Latency Bound
    % All tasks must complete within configured latency bounds

    diagnostic = struct();
    diagnostic.invariant = 'I6_LatencyBound';

    latencies = [];
    maxLatency = 0;
    violationCount = 0;

    for i = 1:length(workers)
        if workers(i).taskCompletionTime > 0
            latency = workers(i).taskCompletionTime - workers(i).taskStartTime;
            latencies(end+1) = latency;
            if latency > maxLatency
                maxLatency = latency;
            end
            if latency > config.workerTimeoutCycles
                violationCount = violationCount + 1;
            end
        end
    end

    pass = (violationCount == 0);

    diagnostic.maxLatency = maxLatency;
    diagnostic.meanLatency = mean(latencies);
    diagnostic.configuredLimit = config.workerTimeoutCycles;
    diagnostic.violationCount = violationCount;
    diagnostic.pass = pass;

    if ~pass
        diagnostic.message = sprintf('%d tasks exceeded latency bound', violationCount);
    end

end
