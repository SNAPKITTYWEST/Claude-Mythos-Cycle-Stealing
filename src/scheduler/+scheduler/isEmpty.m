% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function empty = isEmpty(queues, workerId)
    % Check if a worker's queue is empty

    arguments
        queues struct
        workerId (1,1) uint32 {mustBePositive}
    end

    if workerId > length(queues.workerQueues)
        empty = true;
        return;
    end

    empty = (queues.workerQueues(workerId).taskCount == 0);

end
