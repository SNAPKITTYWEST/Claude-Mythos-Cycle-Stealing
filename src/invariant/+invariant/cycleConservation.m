% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [pass, diagnostic] = cycleConservation(ledger)
    % I1: Cycle Conservation
    % totalInitialCycles == allocatedCycles + availableCycles

    diagnostic = struct();
    diagnostic.invariant = 'I1_CycleConservation';

    % Check conservation law
    allocated = ledger.allocatedCycles;
    available = ledger.availableCycles;
    total = ledger.totalInitialCycles;
    accounted = allocated + available;

    pass = (total == accounted);

    diagnostic.totalInitialCycles = total;
    diagnostic.allocatedCycles = allocated;
    diagnostic.availableCycles = available;
    diagnostic.accountedCycles = accounted;
    diagnostic.difference = total - accounted;
    diagnostic.pass = pass;

    if ~pass
        diagnostic.message = sprintf(...
            'Conservation violated: total=%d, allocated=%d, available=%d, accounted=%d', ...
            total, allocated, available, accounted);
    end

end
