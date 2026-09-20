% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [queues, moveCount] = balance(queues, threshold)
    % Rebalance queues across workers
    % Move tasks from overloaded to underloaded workers

    arguments
        queues struct
        threshold (1,1) {mustBeNonnegative} = 0.15
    end

    moveCount = 0;

    % Get queue depths
    depths = [];
    for i = 1:length(queues.workerQueues)
        depths(i) = queues.workerQueues(i).taskCount;
    end

    meanDepth = mean(depths);
    stdDepth = std(depths);

    % Only rebalance if imbalance exceeds threshold
    maxDepth = max(depths);
    minDepth = min(depths);
    imbalance = (maxDepth - minDepth) / max(1, meanDepth);

    if imbalance < threshold
        return;
    end

    % Find overloaded and underloaded workers
    overloadedThreshold = meanDepth + stdDepth;
    underloadedThreshold = meanDepth - stdDepth;

    for src = 1:length(queues.workerQueues)
        if queues.workerQueues(src).taskCount <= overloadedThreshold
            continue;
        end

        % Find underloaded destination
        for dst = 1:length(queues.workerQueues)
            if dst == src
                continue;
            end

            if queues.workerQueues(dst).taskCount < underloadedThreshold && ...
               queues.workerQueues(src).taskCount > 0

                % Move task from src to dst
                [queues, task, found] = scheduler.dequeue(queues, uint32(src));
                if found
                    [queues, ~] = scheduler.enqueue(queues, uint32(dst), task);
                    moveCount = moveCount + 1;

                    % Record balance event
                    event = struct();
                    event.timestamp = datetime('now');
                    event.operation = 'balance_move';
                    event.fromWorker = src;
                    event.toWorker = dst;
                    event.taskId = task.taskId;

                    if queues.eventCount < queues.maxEvents
                        queues.events(queues.eventCount+1) = event;
                        queues.eventCount = queues.eventCount + 1;
                    end
                end
            end
        end
    end

end
