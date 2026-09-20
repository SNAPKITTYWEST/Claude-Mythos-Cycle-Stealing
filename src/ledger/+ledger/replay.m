% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [ledger, matchStatus, diagnostics] = replay(events, config)
    % Replay a sequence of events to verify determinism
    % I4: Replay with identical trace must reproduce identical final state

    arguments
        events struct
        config struct
    end

    % === Initialize Fresh Ledger ===
    ledger = ledger.create(config.totalInitialCycles, config);

    matchStatus = true;
    diagnostics = struct();
    diagnostics.replayEvents = 0;
    diagnostics.eventMismatches = 0;
    diagnostics.finalStateChecksum = '';

    % === Replay Events ===
    for i = 1:length(events)
        event = events(i);

        switch event.operation
            case 'allocate'
                [ledger, eventId] = ledger.allocate(event.workerId, event.cycles);
                if eventId ~= event.eventId
                    matchStatus = false;
                    diagnostics.eventMismatches = diagnostics.eventMismatches + 1;
                end

            case 'consume'
                [ledger, success, eventId] = ledger.consume(event.workerId, event.cycles);
                if ~success || eventId ~= event.eventId
                    matchStatus = false;
                    diagnostics.eventMismatches = diagnostics.eventMismatches + 1;
                end

            case 'steal'
                [ledger, success, eventId] = ledger.transfer(event.donor, event.thief, event.cycles);
                if ~success || eventId ~= event.eventId
                    matchStatus = false;
                    diagnostics.eventMismatches = diagnostics.eventMismatches + 1;
                end

            case 'return'
                [ledger, eventId] = ledger.returnCycles(event.workerId, event.cycles);
                if eventId ~= event.eventId
                    matchStatus = false;
                    diagnostics.eventMismatches = diagnostics.eventMismatches + 1;
                end
        end

        diagnostics.replayEvents = diagnostics.replayEvents + 1;
    end

    % === Final State Verification ===
    snap = ledger.snapshot();
    diagnostics.finalStateChecksum = char(snap.stateHash);
    diagnostics.replaySuccess = matchStatus && snap.isValid;

end
