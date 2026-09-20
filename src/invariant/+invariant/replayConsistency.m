% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [pass, diagnostic] = replayConsistency(original_snap, replayed_snap)
    % I4: Replay Consistency
    % Replay of identical trace must reproduce identical final state

    diagnostic = struct();
    diagnostic.invariant = 'I4_ReplayConsistency';

    % Compare cycle states
    cycles_match = (original_snap.allocatedCycles == replayed_snap.allocatedCycles) && ...
                   (original_snap.availableCycles == replayed_snap.availableCycles) && ...
                   (original_snap.consumedCycles == replayed_snap.consumedCycles);

    % Compare worker balances
    balances_match = all(original_snap.workerCycles == replayed_snap.workerCycles);

    % Compare event count
    events_match = (original_snap.eventCount == replayed_snap.eventCount);

    pass = cycles_match && balances_match && events_match;

    diagnostic.cyclesMatch = cycles_match;
    diagnostic.balancesMatch = balances_match;
    diagnostic.eventsMatch = events_match;
    diagnostic.originalEventCount = original_snap.eventCount;
    diagnostic.replayedEventCount = replayed_snap.eventCount;
    diagnostic.pass = pass;

    if ~pass
        diagnostic.message = sprintf(...
            'Replay mismatch: cycles=%d, balances=%d, events=%d', ...
            cycles_match, balances_match, events_match);
    end

end
