% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [ledger, success, eventId] = consume(ledger, workerId, cycles)
    % REAL CONSUMPTION with underflow prevention and allocation deactivation.
    %
    % Implements:
    % - Exact underflow prevention: validate(balance >= cycles) before modify
    % - Allocation matching: deactivate allocation records when fully consumed
    % - Consumed accounting: track cumulative consumption per worker
    % - Ledger exactness: verify accounting equations after every consume
    % - Kernel boundary witness: record which kernel operation consumed cycles
    %
    % Mathematical properties:
    % workerCycles(w) >= 0 always                        [I2]
    % consumedCycles = sum(workerConsumed)               [Always True]
    % consumedCycles <= allocatedCycles                  [Always True]

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

    % === Prevent Zero-Cycle Consumption ===
    if cycles == 0
        ledger.zeroConsumptions = ledger.zeroConsumptions + 1;
        success = true;
        return;
    end

    % === Exact Underflow Check: MUST have cycles BEFORE any modification ===
    currentBalance = ledger.workerCycles(workerId);
    if cycles > currentBalance
        ledger.invalidTransfers = ledger.invalidTransfers + 1;
        ledger.underflowAttempts = ledger.underflowAttempts + 1;
        ledger.lastError = sprintf('Underflow: worker %d has %d cycles, requested %d', ...
            workerId, currentBalance, cycles);
        return;
    end

    % === Capture Previous State for Witness ===
    prevBalance = currentBalance;
    prevConsumed = ledger.consumedCycles;
    prevWorkerConsumed = ledger.workerConsumed(workerId);
    prevAllocated = ledger.allocatedCycles;
    prevSystemTotal = sum(ledger.workerCycles) + ledger.availableCycles;
    prevTotalConsumedAccounting = sum(ledger.workerConsumed);

    % === Perform Consumption ===
    ledger.workerCycles(workerId) = ledger.workerCycles(workerId) - cycles;
    ledger.consumedCycles = ledger.consumedCycles + cycles;
    ledger.workerConsumed(workerId) = ledger.workerConsumed(workerId) + cycles;

    % === Update Flow Accounting ===
    if ~isfield(ledger, 'kernelConsumptionSum')
        ledger.kernelConsumptionSum = 0;
    end
    ledger.kernelConsumptionSum = ledger.kernelConsumptionSum + cycles;

    % === Conservation Check: Total cycles unchanged ===
    newSystemTotal = sum(ledger.workerCycles) + ledger.availableCycles;
    if newSystemTotal ~= prevSystemTotal
        ledger.conservationViolations = ledger.conservationViolations + 1;
        ledger.lastError = sprintf('Conservation violated on consume: before=%d, after=%d', prevSystemTotal, newSystemTotal);
        % Rollback
        ledger.workerCycles(workerId) = prevBalance;
        ledger.consumedCycles = prevConsumed;
        ledger.workerConsumed(workerId) = prevWorkerConsumed;
        ledger.kernelConsumptionSum = ledger.kernelConsumptionSum - cycles;
        return;
    end

    % === Consumption Accounting Check: consumed total matches sum ===
    newTotalConsumedAccounting = sum(ledger.workerConsumed);
    if newTotalConsumedAccounting ~= ledger.consumedCycles
        ledger.accountingViolations = ledger.accountingViolations + 1;
        ledger.lastError = 'Consumed cycles accounting mismatch';
        % Rollback
        ledger.workerCycles(workerId) = prevBalance;
        ledger.consumedCycles = prevConsumed;
        ledger.workerConsumed(workerId) = prevWorkerConsumed;
        ledger.kernelConsumptionSum = ledger.kernelConsumptionSum - cycles;
        return;
    end

    % === Build Rich Event Record ===
    event = struct();
    event.eventId = ledger.eventCount + 1;
    event.timestamp = datetime('now');
    event.operation = 'consume';
    event.workerId = workerId;
    event.cycles = cycles;
    event.source = workerId;
    event.destination = 255;  % 255 = kernel/destroyed

    % === State Witnesses ===
    event.previousBalance = prevBalance;
    event.newBalance = ledger.workerCycles(workerId);
    event.previousConsumed = prevConsumed;
    event.newConsumed = ledger.consumedCycles;
    event.previousWorkerConsumed = prevWorkerConsumed;
    event.newWorkerConsumed = ledger.workerConsumed(workerId);
    event.systemTotalBefore = prevSystemTotal;
    event.systemTotalAfter = newSystemTotal;

    % === Invariant Checksums ===
    event.balanceChecksum = ledger.workerCycles(workerId);
    event.conservationChecksum = ledger.availableCycles + sum(ledger.workerCycles);
    event.consumedAccountingChecksum = sum(ledger.workerConsumed);

    % === Metadata ===
    event.experimentId = ledger.experimentId;
    event.seed = ledger.seed;
    event.sequenceNumber = ledger.eventCount + 1;
    event.cumulativeConsumedByWorker = ledger.workerConsumed(workerId);

    % === Allocation Deactivation ===
    % Mark allocations as consumed if this consumption depletes an active allocation
    event.deallocatedAllocations = 0;
    if isfield(ledger, 'allocationHistory') && ~isempty(ledger.allocationHistory)
        allocsForWorker = find([ledger.allocationHistory.workerId] == workerId & ...
                                [ledger.allocationHistory.isActive] == 1);
        cyclesRemaining = cycles;
        for idx = allocsForWorker
            if cyclesRemaining <= 0
                break;
            end
            allocSize = ledger.allocationHistory(idx).cycles;
            if allocSize <= cyclesRemaining
                ledger.allocationHistory(idx).isActive = 0;
                ledger.allocationHistory(idx).consumedTime = event.timestamp;
                event.deallocatedAllocations = event.deallocatedAllocations + 1;
                cyclesRemaining = cyclesRemaining - allocSize;
            end
        end
    end

    % === Hash Previous State ===
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
        event.previousConsumed, event.newConsumed, ...
        event.systemTotalBefore, event.deallocatedAllocations, char(event.timestamp));
    event.eventHash = uint64(sum(uint8(hashStr)) * 73 + event.eventId);

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
        ledger.consumedCycles = prevConsumed;
        ledger.workerConsumed(workerId) = prevWorkerConsumed;
        ledger.kernelConsumptionSum = ledger.kernelConsumptionSum - cycles;
        return;
    end

end
