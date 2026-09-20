% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [ledger, success, eventId] = returnCycles(ledger, workerId, cycles)
    % REAL RETURN with allocation deactivation and conservative allocation accounting.
    %
    % Implements:
    % - Allocation deactivation: mark allocations as returned in history
    % - Balance return: cycles go back to available pool
    % - Allocated cycle accounting: reduce allocatedCycles counter
    % - Return accounting: track cumulative returns per worker
    % - Conservation: system total unchanged
    % - Partial return validation: cannot return more than allocated
    %
    % Mathematical properties:
    % availableCycles + allocatedCycles = totalInitialCycles       [Always]
    % returnedCycles = sum(per-worker returns)                    [Always]
    % allocatedCycles decreases by exact amount returned          [Always]

    arguments
        ledger struct
        workerId (1,1) uint32 {mustBePositive}
        cycles (1,1) {mustBeNonnegative}
    end

    success = false;
    eventId = -1;

    % === Validate Worker ID ===
    if workerId < 1 || workerId > ledger.workerCount
        ledger.invalidTransfers = ledger.invalidTransfers + 1;
        if ~isfield(ledger, 'lastError')
            ledger.lastError = '';
        end
        ledger.lastError = sprintf('Invalid worker ID: %d', workerId);
        return;
    end

    % === Prevent Zero-Cycle Returns ===
    if cycles == 0
        ledger.zeroReturns = ledger.zeroReturns + 1;
        success = true;  % Idempotent
        return;
    end

    % === Validate Return: Cannot return more than currently held ===
    currentBalance = ledger.workerCycles(workerId);
    if cycles > currentBalance
        ledger.invalidTransfers = ledger.invalidTransfers + 1;
        ledger.lastError = sprintf('Cannot return %d cycles, worker %d only has %d', ...
            cycles, workerId, currentBalance);
        return;
    end

    % === Partial Return Check: Must be returning from allocated budget ===
    % In a perfect allocation scheme: worker balance <= what was allocated to that worker
    % We allow returns up to the current balance (which might include stolen cycles)
    if cycles > currentBalance
        ledger.invalidTransfers = ledger.invalidTransfers + 1;
        ledger.partialReturnFailures = ledger.partialReturnFailures + 1;
        ledger.lastError = 'Return exceeds current worker balance';
        return;
    end

    % === Capture Previous State ===
    prevBalance = currentBalance;
    prevAvailable = ledger.availableCycles;
    prevAllocated = ledger.allocatedCycles;
    prevReturned = ledger.returnedCycles;
    prevWorkerReturned = ledger.workerReturned(workerId);
    prevSystemTotal = sum(ledger.workerCycles) + ledger.availableCycles;

    % === Perform Return ===
    ledger.workerCycles(workerId) = ledger.workerCycles(workerId) - cycles;
    ledger.availableCycles = ledger.availableCycles + cycles;
    ledger.allocatedCycles = ledger.allocatedCycles - cycles;
    ledger.returnedCycles = ledger.returnedCycles + cycles;

    % Initialize per-worker return tracking if needed
    if ~isfield(ledger, 'workerReturned')
        ledger.workerReturned = zeros(ledger.workerCount, 1);
    end
    ledger.workerReturned(workerId) = ledger.workerReturned(workerId) + cycles;

    % === Update Flow Accounting ===
    if ~isfield(ledger, 'returnToSystemSum')
        ledger.returnToSystemSum = 0;
    end
    ledger.returnToSystemSum = ledger.returnToSystemSum + cycles;

    % === Conservation Check: Total unchanged ===
    newSystemTotal = sum(ledger.workerCycles) + ledger.availableCycles;
    if newSystemTotal ~= prevSystemTotal
        ledger.conservationViolations = ledger.conservationViolations + 1;
        ledger.lastError = sprintf('Conservation violated on return: before=%d, after=%d', ...
            prevSystemTotal, newSystemTotal);
        % Rollback
        ledger.workerCycles(workerId) = prevBalance;
        ledger.availableCycles = prevAvailable;
        ledger.allocatedCycles = prevAllocated;
        ledger.returnedCycles = prevReturned;
        ledger.workerReturned(workerId) = prevWorkerReturned;
        ledger.returnToSystemSum = ledger.returnToSystemSum - cycles;
        return;
    end

    % === Allocation Accounting Check ===
    % Previously: allocatedCycles should decrease exactly by cycles
    if (prevAllocated - ledger.allocatedCycles) ~= cycles
        ledger.accountingViolations = ledger.accountingViolations + 1;
        ledger.lastError = 'Allocation accounting violation on return';
        % Rollback
        ledger.workerCycles(workerId) = prevBalance;
        ledger.availableCycles = prevAvailable;
        ledger.allocatedCycles = prevAllocated;
        ledger.returnedCycles = prevReturned;
        ledger.workerReturned(workerId) = prevWorkerReturned;
        ledger.returnToSystemSum = ledger.returnToSystemSum - cycles;
        return;
    end

    % === Deactivate Corresponding Allocations ===
    event_deallocatedAllocations = 0;
    if isfield(ledger, 'allocationHistory') && ~isempty(ledger.allocationHistory)
        allocsForWorker = find([ledger.allocationHistory.workerId] == workerId & ...
                                [ledger.allocationHistory.isActive] == 1);
        cyclesRemaining = cycles;
        % Process allocations in reverse order (LIFO for returns)
        for idx = flip(allocsForWorker)
            if cyclesRemaining <= 0
                break;
            end
            allocSize = ledger.allocationHistory(idx).cycles;
            if allocSize <= cyclesRemaining
                ledger.allocationHistory(idx).isActive = 0;
                ledger.allocationHistory(idx).returnedTime = datetime('now');
                ledger.allocationHistory(idx).returnReason = 'worker_return';
                event_deallocatedAllocations = event_deallocatedAllocations + 1;
                cyclesRemaining = cyclesRemaining - allocSize;
            end
        end
    end

    % === Build Rich Event Record ===
    event = struct();
    event.eventId = ledger.eventCount + 1;
    event.timestamp = datetime('now');
    event.operation = 'return';
    event.workerId = workerId;
    event.cycles = cycles;
    event.source = workerId;
    event.destination = 0;  % 0 = system pool

    % === State Witnesses ===
    event.previousBalance = prevBalance;
    event.newBalance = ledger.workerCycles(workerId);
    event.previousAvailable = prevAvailable;
    event.newAvailable = ledger.availableCycles;
    event.previousAllocated = prevAllocated;
    event.newAllocated = ledger.allocatedCycles;
    event.systemTotalBefore = prevSystemTotal;
    event.systemTotalAfter = newSystemTotal;

    % === Invariant Checksums ===
    event.balanceChecksum = ledger.workerCycles(workerId);
    event.conservationChecksum = ledger.availableCycles + sum(ledger.workerCycles);
    event.allocationChecksum = ledger.allocatedCycles + ledger.availableCycles;

    % === Metadata ===
    event.experimentId = ledger.experimentId;
    event.seed = ledger.seed;
    event.sequenceNumber = ledger.eventCount + 1;
    event.cumulativeReturnedByWorker = ledger.workerReturned(workerId);
    event.deallocatedAllocations = event_deallocatedAllocations;

    % === Causal Chain ===
    if ledger.eventCount > 0
        event.previousEventHash = ledger.events(end).eventHash;
        event.previousEventId = ledger.events(end).eventId;
    else
        event.previousEventHash = 0;
        event.previousEventId = 0;
    end

    % === Compute Event Hash ===
    hashStr = sprintf('%d:%d:%d:%d:%d:%d:%d:%d:%d:%s', ...
        event.eventId, event.workerId, event.cycles, ...
        event.previousBalance, event.newBalance, ...
        event.previousAvailable, event.newAvailable, ...
        event.previousAllocated, event_deallocatedAllocations, char(event.timestamp));
    event.eventHash = uint64(sum(uint8(hashStr)) * 83 + event.eventId);

    % === Append to Event Log ===
    if ledger.eventCount < ledger.maxEvents
        if ledger.eventCount == 0
            ledger.events = event;
        else
            ledger.events(end+1) = event;
        end
        ledger.eventCount = ledger.eventCount + 1;
        eventId = event.eventId;
        success = true;
    else
        ledger.eventLogFull = true;
        ledger.lastError = 'Event log capacity exceeded';
        % Rollback
        ledger.workerCycles(workerId) = prevBalance;
        ledger.availableCycles = prevAvailable;
        ledger.allocatedCycles = prevAllocated;
        ledger.returnedCycles = prevReturned;
        ledger.workerReturned(workerId) = prevWorkerReturned;
        ledger.returnToSystemSum = ledger.returnToSystemSum - cycles;
        return;
    end

end
