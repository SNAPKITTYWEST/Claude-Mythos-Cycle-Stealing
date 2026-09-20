% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function snap = snapshot(ledger)
    % Create a snapshot of ledger state for reproducibility
    % Used for replay verification and diagnostics

    snap = struct();

    % === Cycle State ===
    snap.totalInitialCycles = ledger.totalInitialCycles;
    snap.allocatedCycles = ledger.allocatedCycles;
    snap.availableCycles = ledger.availableCycles;
    snap.consumedCycles = ledger.consumedCycles;
    snap.returnedCycles = ledger.returnedCycles;
    snap.stolenCycles = ledger.stolenCycles;

    % === Invariant Check: Conservation ===
    % I1: totalInitialCycles == allocatedCycles + availableCycles + stolenCycles - returnedCycles
    accounted = ledger.allocatedCycles + ledger.availableCycles;
    snap.conservationViolation = ledger.totalInitialCycles ~= accounted;
    snap.conservationError = abs(ledger.totalInitialCycles - accounted);

    % === Worker State ===
    snap.workerCount = ledger.workerCount;
    snap.workerCycles = ledger.workerCycles;
    snap.workerConsumed = ledger.workerConsumed;
    snap.workerStolen = ledger.workerStolen;
    snap.workerReceived = ledger.workerReceived;

    % === Invariant Check: Nonnegative Balances ===
    % I2: All worker cycles >= 0
    snap.negativeBalances = any(ledger.workerCycles < 0);
    snap.negativeBalanceCount = sum(ledger.workerCycles < 0);

    % === Metadata ===
    snap.eventCount = ledger.eventCount;
    snap.timestamp = datetime('now');
    snap.experimentId = ledger.experimentId;
    snap.seed = ledger.seed;

    % === Violations ===
    snap.conservationViolations = ledger.conservationViolations;
    snap.negativeBalanceViolations = ledger.negativeBalanceViolations;
    snap.invalidTransfers = ledger.invalidTransfers;

    % === Hash for Reproducibility Verification ===
    snap.stateHash = getStateHash(snap);

end

function hash = getStateHash(snap)
    % Compute a hash of the snapshot for reproducibility verification
    % This enables detection of non-deterministic behavior

    hashInput = sprintf('%d_%d_%d_%d_%d_%d_%s', ...
        snap.totalInitialCycles, ...
        snap.allocatedCycles, ...
        snap.availableCycles, ...
        snap.consumedCycles, ...
        snap.stolenCycles, ...
        snap.eventCount, ...
        char(snap.timestamp));

    hash = uint32(sum(uint8(hashInput)));
end
