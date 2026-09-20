% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [queues, task, found] = dequeue(queues, workerId)
    % Dequeue next task for a worker (FIFO)

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

    if queue.taskCount == 0
        return;
    end

    % Get first task (FIFO)
    task = queue.tasks(1);
    found = true;

    % Remove from queue
    queues.workerQueues(workerId).tasks = queue.tasks(2:end);
    queues.workerQueues(workerId).taskCount = max(0, queue.taskCount - 1);

    % Update statistics
    queues.totalDequeued = queues.totalDequeued + 1;
    if queues.taskLocation(task.taskId) == workerId
        queues.taskLocation(task.taskId) = -1; % Mark as dequeued
    end

    % Record event
    event = struct();
    event.timestamp = datetime('now');
    event.operation = 'dequeue';
    event.workerId = workerId;
    event.taskId = task.taskId;
    event.queueDepth = queues.workerQueues(workerId).taskCount;

    if queues.eventCount < queues.maxEvents
        queues.events(queues.eventCount+1) = event;
        queues.eventCount = queues.eventCount + 1;
    end

end
