% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [ledger, success, eventId] = consume(ledger, workerId, cycles)
    % Consume cycles from a worker's budget
    % I2: Maintains nonnegative worker balances

    arguments
        ledger struct
        workerId (1,1) uint32 {mustBePositive}
        cycles (1,1) {mustBeNonnegative}
    end

    success = false;
    eventId = -1;

    % === Validation ===
    if workerId > ledger.workerCount
        ledger.invalidTransfers = ledger.invalidTransfers + 1;
        return;
    end

    if cycles > ledger.workerCycles(workerId)
        ledger.invalidTransfers = ledger.invalidTransfers + 1;
        return; % Cannot consume more than available
    end

    % === Consumption ===
    ledger.workerCycles(workerId) = ledger.workerCycles(workerId) - cycles;
    ledger.consumedCycles = ledger.consumedCycles + cycles;
    ledger.workerConsumed(workerId) = ledger.workerConsumed(workerId) + cycles;

    % === Event Logging ===
    event = struct();
    event.eventId = ledger.eventCount + 1;
    event.timestamp = datetime('now');
    event.operation = 'consume';
    event.workerId = workerId;
    event.cycles = cycles;
    event.source = workerId;
    event.destination = 'kernel';
    event.previousBalance = ledger.workerCycles(workerId) + cycles;
    event.newBalance = ledger.workerCycles(workerId);
    event.experimentId = ledger.experimentId;
    event.seed = ledger.seed;

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
        error('Event log full');
    end

end
