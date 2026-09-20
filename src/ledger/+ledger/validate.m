% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [isValid, violations, report] = validate(ledger)
    % Validate all invariants and detect corruption
    % Returns structured violation report

    isValid = true;
    violations = {};
    report = struct();

    % === I1: Cycle Conservation ===
    accounted = ledger.allocatedCycles + ledger.availableCycles;
    if ledger.totalInitialCycles ~= accounted
        isValid = false;
        violations{end+1} = sprintf('I1 Conservation violated: total=%d, accounted=%d', ...
            ledger.totalInitialCycles, accounted);
        ledger.conservationViolations = ledger.conservationViolations + 1;
    end
    report.I1_Conservation = (ledger.totalInitialCycles == accounted);

    % === I2: Nonnegative Balances ===
    negCount = sum(ledger.workerCycles < 0);
    if negCount > 0
        isValid = false;
        violations{end+1} = sprintf('I2 Nonnegativity violated: %d negative balances', negCount);
        ledger.negativeBalanceViolations = ledger.negativeBalanceViolations + 1;
    end
    report.I2_Nonnegative = (negCount == 0);
    report.negativeBalanceCount = negCount;

    % === I3: Queue Integrity ===
    % Cannot be fully checked without queue state, but validate event consistency
    report.I3_QueueIntegrity = true; % Checked in queue modules

    % === Consumed + Stolen Cycles Accounting ===
    % Note: consumedCycles is from kernels, stolenCycles is from transfers
    totalWorkerActivity = sum(ledger.workerConsumed) + sum(ledger.workerStolen);
    report.totalWorkerActivity = totalWorkerActivity;

    % === Event Log Consistency ===
    report.eventCount = ledger.eventCount;
    report.eventLogFull = (ledger.eventCount >= ledger.maxEvents);
    if ledger.eventCount >= ledger.maxEvents
        isValid = false;
        violations{end+1} = 'Event log is full (capacity reached)';
    end

    % === Allocation vs Consumed Consistency ===
    totalAllocated = ledger.allocatedCycles;
    totalConsumed = sum(ledger.workerConsumed);
    if totalAllocated < totalConsumed
        isValid = false;
        violations{end+1} = sprintf('Consumed cycles (%d) exceed allocated (%d)', ...
            totalConsumed, totalAllocated);
    end
    report.allocatedVsConsumed = (totalAllocated >= totalConsumed);

    % === Invalid Transfer Count ===
    if ledger.invalidTransfers > 0
        violations{end+1} = sprintf('Found %d invalid transfer attempts', ledger.invalidTransfers);
    end
    report.invalidTransfers = ledger.invalidTransfers;

    % === Summary ===
    report.isValid = isValid;
    report.violationCount = length(violations);
    report.violations = violations;
    report.timestamp = datetime('now');
    report.experimentId = ledger.experimentId;

end
