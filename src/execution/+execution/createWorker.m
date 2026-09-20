% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function worker = createWorker(workerId, initialCycles)
    % Create a new worker with initial state

    arguments
        workerId (1,1) uint32 {mustBePositive}
        initialCycles (1,1) {mustBeNonnegative}
    end

    worker = struct();
    worker.workerId = workerId;
    worker.cycleCount = initialCycles;
    worker.cyclesPeak = initialCycles;
    worker.cyclesMinimum = initialCycles;

    % Task tracking
    worker.tasksCreated = 0;
    worker.tasksCompleted = 0;
    worker.tasksFailed = 0;
    worker.tasksRunning = 0;

    % Cycle tracking
    worker.cyclesAllocated = initialCycles;
    worker.cyclesConsumed = 0;
    worker.cyclesStolen = 0;
    worker.cyclesReceived = 0;
    worker.cyclesReturned = 0;

    % Latency tracking
    worker.latencyMin = inf;
    worker.latencyMax = 0;
    worker.latencySum = 0;
    worker.latencyCount = 0;

    % Stealing tracking
    worker.stealAttempts = 0;
    worker.stealSuccesses = 0;
    worker.stealFailures = 0;

    % State
    worker.isIdle = true;
    worker.lastActivityTime = datetime('now');
    worker.creationTime = datetime('now');

end
