% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [queues, taskId] = enqueue(queues, workerId, task)
    % Enqueue a task for a worker
    % I3: No task may exist in two queues simultaneously

    arguments
        queues struct
        workerId (1,1) uint32 {mustBePositive}
        task struct
    end

    if workerId > length(queues.workerQueues)
        error('Invalid worker ID: %d', workerId);
    end

    taskId = queues.nextTaskId;

    % Add task to worker queue
    if isempty(queues.workerQueues(workerId).tasks)
        queues.workerQueues(workerId).tasks = task;
    else
        queues.workerQueues(workerId).tasks(end+1) = task;
    end

    % Track task location
    queues.taskLocation(taskId) = workerId;
    queues.workerQueues(workerId).taskCount = queues.workerQueues(workerId).taskCount + 1;

    % Update statistics
    queues.totalEnqueued = queues.totalEnqueued + 1;
    queues.nextTaskId = queues.nextTaskId + 1;

    % Record event
    event = struct();
    event.timestamp = datetime('now');
    event.operation = 'enqueue';
    event.workerId = workerId;
    event.taskId = taskId;
    event.queueDepth = queues.workerQueues(workerId).taskCount;

    if queues.eventCount < queues.maxEvents
        queues.events(queues.eventCount+1) = event;
        queues.eventCount = queues.eventCount + 1;
    end

end
