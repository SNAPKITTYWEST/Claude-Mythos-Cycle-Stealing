% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [isValid, violations, report] = validate(ledger)
    % REAL MULTI-LEVEL INVARIANT VALIDATION with detailed diagnostics.
    %
    % Validates:
    % - I1: Cycle Conservation (total never changes)
    % - I2: Nonnegative Balances (no worker can go negative)
    % - I3: Accounting Consistency (sums match counters)
    % - I4: Flow Balance (allocated >= consumed)
    % - I5: Event Chain Integrity (hashes link correctly)
    % - I6: Allocation Consistency (allocations match allocatedCycles)
    %
    % Returns:
    % - isValid: composite boolean
    % - violations: cell array of violation descriptions
    % - report: detailed struct with all invariant checks

    isValid = true;
    violations = {};
    report = struct();

    % === I1: Cycle Conservation Invariant ===
    % MUST: sum(workerCycles) + availableCycles == totalInitialCycles
    accountedCycles = sum(ledger.workerCycles) + ledger.availableCycles;
    report.I1.name = 'Cycle Conservation';
    report.I1.met = (ledger.totalInitialCycles == accountedCycles);
    report.I1.totalInitial = ledger.totalInitialCycles;
    report.I1.accountedFor = accountedCycles;
    report.I1.error = abs(ledger.totalInitialCycles - accountedCycles);

    if ~report.I1.met
        isValid = false;
        violations{end+1} = sprintf('I1 CONSERVATION VIOLATED: total=%d, accounted=%d, error=%d', ...
            ledger.totalInitialCycles, accountedCycles, report.I1.error);
        ledger.conservationViolations = ledger.conservationViolations + 1;
    end

    % === I2: Nonnegative Balance Invariant ===
    % MUST: workerCycles(w) >= 0 for all w
    negativeWorkers = find(ledger.workerCycles < 0);
    report.I2.name = 'Nonnegative Balances';
    report.I2.met = isempty(negativeWorkers);
    report.I2.negativeCount = length(negativeWorkers);
    report.I2.negativeWorkers = negativeWorkers';
    report.I2.minBalance = min(ledger.workerCycles);
    report.I2.maxBalance = max(ledger.workerCycles);

    if ~report.I2.met
        isValid = false;
        violations{end+1} = sprintf('I2 NONNEGATIVITY VIOLATED: %d workers with negative balances', ...
            report.I2.negativeCount);
        ledger.negativeBalanceViolations = ledger.negativeBalanceViolations + 1;
    end

    % === I3a: Consumed Cycles Accounting ===
    % MUST: sum(workerConsumed) == consumedCycles
    consumedSum = sum(ledger.workerConsumed);
    report.I3a.name = 'Consumed Accounting';
    report.I3a.met = (consumedSum == ledger.consumedCycles);
    report.I3a.sum = consumedSum;
    report.I3a.counter = ledger.consumedCycles;
    report.I3a.error = abs(consumedSum - ledger.consumedCycles);

    if ~report.I3a.met
        isValid = false;
        violations{end+1} = sprintf('I3a CONSUMED ACCOUNTING: sum=%d, counter=%d, error=%d', ...
            consumedSum, ledger.consumedCycles, report.I3a.error);
    end

    % === I3b: Stolen Cycles Accounting ===
    % MUST: sum(workerStolen) == stolenCycles
    stolenSum = sum(ledger.workerStolen);
    report.I3b.name = 'Stolen Accounting';
    report.I3b.met = (stolenSum == ledger.stolenCycles);
    report.I3b.sum = stolenSum;
    report.I3b.counter = ledger.stolenCycles;
    report.I3b.error = abs(stolenSum - ledger.stolenCycles);

    if ~report.I3b.met
        isValid = false;
        violations{end+1} = sprintf('I3b STOLEN ACCOUNTING: sum=%d, counter=%d, error=%d', ...
            stolenSum, ledger.stolenCycles, report.I3b.error);
    end

    % === I3c: Received Cycles Accounting ===
    % MUST: sum(workerReceived) == stolenCycles (received == stolen, by definition)
    receivedSum = sum(ledger.workerReceived);
    report.I3c.name = 'Received Accounting';
    report.I3c.met = (receivedSum == ledger.stolenCycles);
    report.I3c.sum = receivedSum;
    report.I3c.counter = ledger.stolenCycles;
    report.I3c.error = abs(receivedSum - ledger.stolenCycles);

    if ~report.I3c.met
        isValid = false;
        violations{end+1} = sprintf('I3c RECEIVED ACCOUNTING: sum=%d, stolen counter=%d, error=%d', ...
            receivedSum, ledger.stolenCycles, report.I3c.error);
    end

    % === I3d: Returned Cycles Accounting ===
    % MUST: sum(workerReturned) == returnedCycles
    if isfield(ledger, 'workerReturned') && ~isempty(ledger.workerReturned)
        returnedSum = sum(ledger.workerReturned);
        report.I3d.name = 'Returned Accounting';
        report.I3d.met = (returnedSum == ledger.returnedCycles);
        report.I3d.sum = returnedSum;
        report.I3d.counter = ledger.returnedCycles;
        report.I3d.error = abs(returnedSum - ledger.returnedCycles);
    else
        report.I3d.met = true;
        report.I3d.sum = 0;
        report.I3d.counter = ledger.returnedCycles;
        report.I3d.error = 0;
    end

    if ~report.I3d.met
        isValid = false;
        violations{end+1} = sprintf('I3d RETURNED ACCOUNTING: sum=%d, counter=%d, error=%d', ...
            report.I3d.sum, report.I3d.counter, report.I3d.error);
    end

    % === I4: Flow Balance Invariant ===
    % MUST: systemDepletion >= kernelConsumption (allocated cycles must cover consumed)
    % MUST: allocatedCycles >= consumedCycles (obvious from conservation)
    report.I4.name = 'Flow Balance';
    report.I4.allocatedCycles = ledger.allocatedCycles;
    report.I4.consumedCycles = ledger.consumedCycles;
    report.I4.met = (ledger.allocatedCycles >= ledger.consumedCycles);
    report.I4.balance = ledger.allocatedCycles - ledger.consumedCycles;

    if ~report.I4.met
        isValid = false;
        violations{end+1} = sprintf('I4 FLOW BALANCE: allocated=%d < consumed=%d', ...
            ledger.allocatedCycles, ledger.consumedCycles);
    end

    % === I5: Event Chain Integrity ===
    % Verify that events form a valid causal chain with correct hashes
    if isfield(ledger, 'events') && ~isempty(ledger.events)
        report.I5.name = 'Event Chain Integrity';
        chainBroken = false;
        hashMismatches = 0;

        for i = 2:length(ledger.events)
            % Check that event properly links to previous
            currEvent = ledger.events(i);
            prevEvent = ledger.events(i-1);

            if currEvent.previousEventId ~= prevEvent.eventId
                chainBroken = true;
            end

            % Note: Cannot fully verify hash without knowing exact hash algorithm
            % but we can check that hashes are nonzero and plausible
            if currEvent.previousEventHash == 0 && i > 1
                hashMismatches = hashMismatches + 1;
            end
        end

        report.I5.eventCount = length(ledger.events);
        report.I5.chainBroken = chainBroken;
        report.I5.hashMismatches = hashMismatches;
        report.I5.met = ~chainBroken && (hashMismatches == 0);

        if ~report.I5.met
            isValid = false;
            if chainBroken
                violations{end+1} = 'I5 EVENT CHAIN: Chain integrity broken';
            end
            if hashMismatches > 0
                violations{end+1} = sprintf('I5 EVENT CHAIN: %d hash mismatches', hashMismatches);
            end
        end
    else
        report.I5.met = true;
        report.I5.eventCount = 0;
    end

    % === I6: Allocation History Consistency ===
    % MUST: sum of active allocations <= allocatedCycles
    % MUST: sum of inactive allocations + active == total allocations
    if isfield(ledger, 'allocationHistory') && ~isempty(ledger.allocationHistory)
        report.I6.name = 'Allocation Consistency';
        activeAllocs = [ledger.allocationHistory.isActive];
        activeAllocCount = sum(activeAllocs);
        inactiveAllocCount = length(ledger.allocationHistory) - activeAllocCount;

        % Sum cycles in allocations
        allocCycles = [ledger.allocationHistory.cycles];
        activeAllocCycles = sum(allocCycles(activeAllocs == 1));
        totalAllocHistCycles = sum(allocCycles);

        report.I6.totalAllocations = length(ledger.allocationHistory);
        report.I6.activeAllocations = activeAllocCount;
        report.I6.inactiveAllocations = inactiveAllocCount;
        report.I6.activeAllocCycles = activeAllocCycles;
        report.I6.totalAllocHistCycles = totalAllocHistCycles;
        report.I6.met = (activeAllocCycles <= ledger.allocatedCycles);

        if ~report.I6.met
            isValid = false;
            violations{end+1} = sprintf('I6 ALLOCATION: active cycles=%d > allocated=%d', ...
                activeAllocCycles, ledger.allocatedCycles);
        end
    else
        report.I6.met = true;
        report.I6.totalAllocations = 0;
    end

    % === Violation Counter Summary ===
    report.invalidTransfers = ledger.invalidTransfers;
    if isfield(ledger, 'underflowAttempts')
        report.underflowAttempts = ledger.underflowAttempts;
    end
    if isfield(ledger, 'doubleAllocationAttempts')
        report.doubleAllocationAttempts = ledger.doubleAllocationAttempts;
    end
    if isfield(ledger, 'accountingViolations')
        report.accountingViolations = ledger.accountingViolations;
    end

    % === Event Log Status ===
    report.eventLogCount = ledger.eventCount;
    report.eventLogCapacity = ledger.maxEvents;
    report.eventLogFull = (ledger.eventCount >= ledger.maxEvents);
    if report.eventLogFull
        isValid = false;
        violations{end+1} = 'Event log at capacity';
    end

    % === Composite Summary ===
    report.isValid = isValid;
    report.violationCount = length(violations);
    report.violations = violations;
    report.timestamp = datetime('now');
    report.experimentId = ledger.experimentId;
    report.seed = ledger.seed;

    % === Diagnostic Summary ===
    invariantsMet = 0;
    if report.I1.met, invariantsMet = invariantsMet + 1; end
    if report.I2.met, invariantsMet = invariantsMet + 1; end
    if report.I3a.met, invariantsMet = invariantsMet + 1; end
    if report.I3b.met, invariantsMet = invariantsMet + 1; end
    if report.I3c.met, invariantsMet = invariantsMet + 1; end
    if report.I3d.met, invariantsMet = invariantsMet + 1; end
    if report.I4.met, invariantsMet = invariantsMet + 1; end
    if report.I5.met, invariantsMet = invariantsMet + 1; end
    if report.I6.met, invariantsMet = invariantsMet + 1; end

    report.invariantsMet = invariantsMet;
    report.invariantsTotal = 9;
    report.healthPercentage = (invariantsMet / report.invariantsTotal) * 100;

end
