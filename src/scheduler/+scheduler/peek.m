% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [task, found] = peek(queues, workerId)
    % Peek at next task without dequeuing

    arguments
        queues struct
        workerId (1,1) uint32 {mustBePositive}
    end

    task = [];
    found = false;

    if workerId > length(queues.workerQueues)
        return;
    end

    queue = queues.workerQueues(workerId);

    if queue.taskCount > 0
        task = queue.tasks(1);
        found = true;
    end

end
