% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [ledger, eventId] = returnCycles(ledger, workerId, cycles)
    % Return unused cycles from worker back to available pool
    % Used to handle overallocation corrections

    arguments
        ledger struct
        workerId (1,1) uint32 {mustBePositive}
        cycles (1,1) {mustBeNonnegative}
    end

    if workerId > ledger.workerCount
        error('Invalid worker ID: %d', workerId);
    end

    if cycles > ledger.workerCycles(workerId)
        error('Cannot return %d cycles, worker only has %d', cycles, ledger.workerCycles(workerId));
    end

    % === Return ===
    ledger.workerCycles(workerId) = ledger.workerCycles(workerId) - cycles;
    ledger.availableCycles = ledger.availableCycles + cycles;
    ledger.allocatedCycles = ledger.allocatedCycles - cycles;
    ledger.returnedCycles = ledger.returnedCycles + cycles;

    % === Event Logging ===
    event = struct();
    event.eventId = ledger.eventCount + 1;
    event.timestamp = datetime('now');
    event.operation = 'return';
    event.workerId = workerId;
    event.cycles = cycles;
    event.source = workerId;
    event.destination = 'available';
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
    else
        error('Event log full');
    end

end
