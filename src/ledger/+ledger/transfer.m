% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [ledger, success, eventId] = transfer(ledger, fromWorkerId, toWorkerId, cycles)
    % Transfer cycles from one worker to another
    % Used in cycle stealing: never creates or destroys cycles

    arguments
        ledger struct
        fromWorkerId (1,1) uint32 {mustBePositive}
        toWorkerId (1,1) uint32 {mustBePositive}
        cycles (1,1) {mustBeNonnegative}
    end

    success = false;
    eventId = -1;

    % === Validation ===
    if fromWorkerId > ledger.workerCount || toWorkerId > ledger.workerCount
        ledger.invalidTransfers = ledger.invalidTransfers + 1;
        return;
    end

    if fromWorkerId == toWorkerId
        return; % Self-transfer is no-op
    end

    if cycles > ledger.workerCycles(fromWorkerId)
        ledger.invalidTransfers = ledger.invalidTransfers + 1;
        return; % Cannot steal more than available
    end

    % === Transfer (No cycle creation/destruction) ===
    previousFromBalance = ledger.workerCycles(fromWorkerId);
    previousToBalance = ledger.workerCycles(toWorkerId);

    ledger.workerCycles(fromWorkerId) = previousFromBalance - cycles;
    ledger.workerCycles(toWorkerId) = previousToBalance + cycles;
    ledger.stolenCycles = ledger.stolenCycles + cycles;
    ledger.workerStolen(fromWorkerId) = ledger.workerStolen(fromWorkerId) + cycles;
    ledger.workerReceived(toWorkerId) = ledger.workerReceived(toWorkerId) + cycles;

    % === Event Logging ===
    event = struct();
    event.eventId = ledger.eventCount + 1;
    event.timestamp = datetime('now');
    event.operation = 'steal';
    event.thief = toWorkerId;
    event.donor = fromWorkerId;
    event.cycles = cycles;
    event.source = fromWorkerId;
    event.destination = toWorkerId;
    event.donorPreviousBalance = previousFromBalance;
    event.donorNewBalance = ledger.workerCycles(fromWorkerId);
    event.thiefPreviousBalance = previousToBalance;
    event.thiefNewBalance = ledger.workerCycles(toWorkerId);
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
