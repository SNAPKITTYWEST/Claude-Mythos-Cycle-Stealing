% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [pass, diagnostic] = queueIntegrity(queues)
    % I3: Queue Integrity
    % No task may simultaneously exist in two queues

    diagnostic = struct();
    diagnostic.invariant = 'I3_QueueIntegrity';

    % Collect all tasks from all queues
    all_tasks = [];
    task_count_by_worker = [];

    for i = 1:length(queues.workerQueues)
        tasks = queues.workerQueues(i).tasks;
        task_count_by_worker(i) = length(tasks);
        for j = 1:length(tasks)
            all_tasks(end+1) = tasks(j).taskId;
        end
    end

    % Check for duplicates
    [unique_tasks, idx] = unique(all_tasks);
    duplicates = length(all_tasks) - length(unique_tasks);

    pass = (duplicates == 0);

    diagnostic.totalTasksInQueues = length(all_tasks);
    diagnostic.uniqueTaskCount = length(unique_tasks);
    diagnostic.duplicateTaskCount = duplicates;
    diagnostic.taskCountByWorker = task_count_by_worker;
    diagnostic.pass = pass;

    if ~pass
        diagnostic.message = sprintf('%d tasks appear in multiple queues', duplicates);
    end

end
