% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function size = getQueueSize(queues, workerId)
    % Get the current size of a worker's queue

    arguments
        queues struct
        workerId (1,1) uint32 {mustBePositive}
    end

    if workerId > length(queues.workerQueues)
        size = 0;
        return;
    end

    size = queues.workerQueues(workerId).taskCount;

end
