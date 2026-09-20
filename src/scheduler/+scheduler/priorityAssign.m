% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function queues = priorityAssign(queues, taskId, priority)
    % Assign priority to a task (higher = more important)

    arguments
        queues struct
        taskId (1,1) {mustBePositive}
        priority (1,1) {mustBeNonnegative}
    end

    % Find task location
    if taskId > length(queues.taskLocation)
        return;
    end

    workerId = queues.taskLocation(taskId);
    if workerId <= 0 || workerId > length(queues.workerQueues)
        return;
    end

    % Find and update task priority
    queue = queues.workerQueues(workerId).tasks;
    for i = 1:length(queue)
        if queue(i).taskId == taskId
            queue(i).priority = priority;
            queues.workerQueues(workerId).tasks = queue;

            % Re-sort if priority queue type
            if strcmp(queues.type, 'Priority')
                queues.workerQueues(workerId).tasks = sortByPriority(...
                    queues.workerQueues(workerId).tasks);
            end
            break;
        end
    end

end

function tasks = sortByPriority(tasks)
    % Sort tasks by priority (descending)
    if isempty(tasks)
        return;
    end

    priorities = [tasks.priority];
    [~, idx] = sort(priorities, 'descend');
    tasks = tasks(idx);
end
