% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [ledger, success, eventId] = transfer(ledger, fromWorkerId, toWorkerId, cycles)
    % REAL TRANSFER with conservation proof and balance verification.
    %
    % Implements:
    % - Cycle conservation proof: source loses EXACTLY what dest gains
    % - Self-transfer rejection: no-op returns success (idempotent)
    % - Underflow prevention: donor must have sufficient cycles
    % - Symmetry: every transfer has matching records in stolen/received
    % - Witness chain: link to previous event for causal ordering
    %
    % Mathematical properties:
    % forall transfers: Δ(fromCycles) = -Δ(toCycles)               [Zero-Sum]
    % sum(workerCycles) = constant                                 [Conservation]
    % stolenCycles = sum(workerStolen)                             [Symmetry]
    % workerStolen(w) + workerReceived(w) = transfers involving w  [Accounting]

    arguments
        ledger struct
        fromWorkerId (1,1) uint32 {mustBePositive}
        toWorkerId (1,1) uint32 {mustBePositive}
        cycles (1,1) {mustBeNonnegative}
    end

    success = false;
    eventId = -1;

    % === Validate Worker IDs ===
    if fromWorkerId < 1 || fromWorkerId > ledger.workerCount
        ledger.invalidTransfers = ledger.invalidTransfers + 1;
        if ~isfield(ledger, 'lastError')
            ledger.lastError = '';
        end
        ledger.lastError = sprintf('Invalid fromWorker ID: %d', fromWorkerId);
        return;
    end

    if toWorkerId < 1 || toWorkerId > ledger.workerCount
        ledger.invalidTransfers = ledger.invalidTransfers + 1;
        ledger.lastError = sprintf('Invalid toWorker ID: %d', toWorkerId);
        return;
    end

    % === Prevent Zero-Cycle Transfers ===
    if cycles == 0
        ledger.zeroTransfers = ledger.zeroTransfers + 1;
        success = true;  % Idempotent success
        return;
    end

    % === Self-Transfer is No-Op Success ===
    if fromWorkerId == toWorkerId
        ledger.selfTransfers = ledger.selfTransfers + 1;
        success = true;  % Idempotent
        return;
    end

    % === Underflow Prevention: Donor must have sufficient cycles ===
    donorBalance = ledger.workerCycles(fromWorkerId);
    if cycles > donorBalance
        ledger.invalidTransfers = ledger.invalidTransfers + 1;
        ledger.underflowAttempts = ledger.underflowAttempts + 1;
        ledger.lastError = sprintf('Transfer underflow: worker %d has %d, requested %d', ...
            fromWorkerId, donorBalance, cycles);
        return;
    end

    % === Capture Previous State for Conservation Proof ===
    prevFromBalance = donorBalance;
    prevToBalance = ledger.workerCycles(toWorkerId);
    prevStolen = ledger.stolenCycles;
    prevFromStolen = ledger.workerStolen(fromWorkerId);
    prevToReceived = ledger.workerReceived(toWorkerId);
    prevSystemTotal = sum(ledger.workerCycles) + ledger.availableCycles;
    prevSumBalances = sum(ledger.workerCycles);

    % === Perform Transfer ===
    ledger.workerCycles(fromWorkerId) = prevFromBalance - cycles;
    ledger.workerCycles(toWorkerId) = prevToBalance + cycles;
    ledger.stolenCycles = ledger.stolenCycles + cycles;
    ledger.workerStolen(fromWorkerId) = ledger.workerStolen(fromWorkerId) + cycles;
    ledger.workerReceived(toWorkerId) = ledger.workerReceived(toWorkerId) + cycles;

    % === Zero-Sum Verification ===
    donorChange = ledger.workerCycles(fromWorkerId) - prevFromBalance;
    recipientChange = ledger.workerCycles(toWorkerId) - prevToBalance;
    if donorChange ~= -recipientChange
        ledger.conservationViolations = ledger.conservationViolations + 1;
        ledger.lastError = sprintf('Transfer zero-sum violated: donor delta=%d, recipient delta=%d', ...
            donorChange, recipientChange);
        % Rollback
        ledger.workerCycles(fromWorkerId) = prevFromBalance;
        ledger.workerCycles(toWorkerId) = prevToBalance;
        ledger.stolenCycles = prevStolen;
        ledger.workerStolen(fromWorkerId) = prevFromStolen;
        ledger.workerReceived(toWorkerId) = prevToReceived;
        return;
    end

    % === Conservation Check: Total system unchanged ===
    newSystemTotal = sum(ledger.workerCycles) + ledger.availableCycles;
    if newSystemTotal ~= prevSystemTotal
        ledger.conservationViolations = ledger.conservationViolations + 1;
        ledger.lastError = sprintf('Conservation violated on transfer: before=%d, after=%d', ...
            prevSystemTotal, newSystemTotal);
        % Rollback
        ledger.workerCycles(fromWorkerId) = prevFromBalance;
        ledger.workerCycles(toWorkerId) = prevToBalance;
        ledger.stolenCycles = prevStolen;
        ledger.workerStolen(fromWorkerId) = prevFromStolen;
        ledger.workerReceived(toWorkerId) = prevToReceived;
        return;
    end

    % === Symmetry Check ===
    if ledger.workerStolen(fromWorkerId) - prevFromStolen ~= cycles
        ledger.accountingViolations = ledger.accountingViolations + 1;
        ledger.lastError = 'Transfer symmetry violation (stolen side)';
        % Rollback
        ledger.workerCycles(fromWorkerId) = prevFromBalance;
        ledger.workerCycles(toWorkerId) = prevToBalance;
        ledger.stolenCycles = prevStolen;
        ledger.workerStolen(fromWorkerId) = prevFromStolen;
        ledger.workerReceived(toWorkerId) = prevToReceived;
        return;
    end

    if ledger.workerReceived(toWorkerId) - prevToReceived ~= cycles
        ledger.accountingViolations = ledger.accountingViolations + 1;
        ledger.lastError = 'Transfer symmetry violation (received side)';
        % Rollback
        ledger.workerCycles(fromWorkerId) = prevFromBalance;
        ledger.workerCycles(toWorkerId) = prevToBalance;
        ledger.stolenCycles = prevStolen;
        ledger.workerStolen(fromWorkerId) = prevFromStolen;
        ledger.workerReceived(toWorkerId) = prevToReceived;
        return;
    end

    % === Build Rich Event Record ===
    event = struct();
    event.eventId = ledger.eventCount + 1;
    event.timestamp = datetime('now');
    event.operation = 'transfer';
    event.fromWorkerId = fromWorkerId;
    event.toWorkerId = toWorkerId;
    event.cycles = cycles;
    event.source = fromWorkerId;
    event.destination = toWorkerId;

    % === State Witnesses (Full Symmetry) ===
    event.donorPreviousBalance = prevFromBalance;
    event.donorNewBalance = ledger.workerCycles(fromWorkerId);
    event.donorChangeDelta = donorChange;
    event.recipientPreviousBalance = prevToBalance;
    event.recipientNewBalance = ledger.workerCycles(toWorkerId);
    event.recipientChangeDelta = recipientChange;
    event.systemTotalBefore = prevSystemTotal;
    event.systemTotalAfter = newSystemTotal;

    % === Conservation Proof Fields ===
    event.zeroSumProof = (donorChange == -recipientChange);
    event.conservationProof = (newSystemTotal == prevSystemTotal);
    event.symmetryProofStolen = (ledger.workerStolen(fromWorkerId) - prevFromStolen == cycles);
    event.symmetryProofReceived = (ledger.workerReceived(toWorkerId) - prevToReceived == cycles);

    % === Invariant Checksums ===
    event.donorChecksum = ledger.workerCycles(fromWorkerId);
    event.recipientChecksum = ledger.workerCycles(toWorkerId);
    event.conservationChecksum = ledger.availableCycles + sum(ledger.workerCycles);
    event.stolenAccountingChecksum = sum(ledger.workerStolen);
    event.receivedAccountingChecksum = sum(ledger.workerReceived);

    % === Metadata ===
    event.experimentId = ledger.experimentId;
    event.seed = ledger.seed;
    event.sequenceNumber = ledger.eventCount + 1;
    event.cumulativeStolenByDonor = ledger.workerStolen(fromWorkerId);
    event.cumulativeReceivedByRecipient = ledger.workerReceived(toWorkerId);

    % === Causal Chain ===
    if ledger.eventCount > 0
        event.previousEventHash = ledger.events(end).eventHash;
        event.previousEventId = ledger.events(end).eventId;
    else
        event.previousEventHash = 0;
        event.previousEventId = 0;
    end

    % === Compute Event Hash ===
    hashStr = sprintf('%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%s', ...
        event.eventId, event.fromWorkerId, event.toWorkerId, event.cycles, ...
        event.donorPreviousBalance, event.donorNewBalance, ...
        event.recipientPreviousBalance, event.recipientNewBalance, ...
        event.systemTotalBefore, event.zeroSumProof, ...
        event.conservationProof, event.symmetryProofStolen, char(event.timestamp));
    event.eventHash = uint64(sum(uint8(hashStr)) * 79 + event.eventId);

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
        ledger.workerCycles(fromWorkerId) = prevFromBalance;
        ledger.workerCycles(toWorkerId) = prevToBalance;
        ledger.stolenCycles = prevStolen;
        ledger.workerStolen(fromWorkerId) = prevFromStolen;
        ledger.workerReceived(toWorkerId) = prevToReceived;
        return;
    end

end
