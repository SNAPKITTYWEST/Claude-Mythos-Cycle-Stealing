% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [queues, decisions] = schedulerStep(queues, ledger, config)
    % Execute one scheduling step
    % Checks for rebalancing and makes scheduling decisions

    arguments
        queues struct
        ledger struct
        config struct
    end

    decisions = struct();
    decisions.timestamp = datetime('now');
    decisions.balancingDecision = false;
    decisions.tasksToSchedule = [];
    decisions.workerAssignments = [];
    decisions.stealingRequests = [];

    % Check if rebalancing should occur
    state = scheduler.queueState(queues);
    if state.depthImbalance > config.rebalanceThreshold * max(1, state.maxDepth)
        [queues, moveCount] = scheduler.balance(queues, config.rebalanceThreshold);
        decisions.balancingDecision = true;
        decisions.balanceMoveCount = moveCount;
    end

    % Prepare task assignments for workers with available cycles
    taskCount = 0;
    for i = 1:length(queues.workerQueues)
        if ledger.workerCycles(i) > config.taskWorkUnits && ...
           ~scheduler.isEmpty(queues, uint32(i))

            [task, found] = scheduler.peek(queues, uint32(i));
            if found
                taskCount = taskCount + 1;
                decisions.tasksToSchedule(taskCount).workerId = i;
                decisions.tasksToSchedule(taskCount).taskId = task.taskId;
            end
        end
    end

    decisions.scheduledTaskCount = taskCount;

end
