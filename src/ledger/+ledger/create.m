% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function ledger = create(totalCycles, config)
    % Create a new cycle ledger with conservation invariant
    % I1: initialCycles == accountedCycles at all times

    arguments
        totalCycles (1,1) {mustBePositive}
        config struct
    end

     ledger = struct();

    % === Cycle Accounting ===
    ledger.totalInitialCycles = totalCycles;
    ledger.allocatedCycles = 0;
    ledger.availableCycles = totalCycles;
    ledger.consumedCycles = 0;
    ledger.returnedCycles = 0;
    ledger.stolenCycles = 0;

    % === Event Log ===
     ledger.events = [];
    ledger.eventCount = 0;
    ledger.maxEvents = 1e6; % safety limit

    % === Worker State ===
     ledger.workerCount = config.workerCount;
    ledger.workerCycles = zeros(config.workerCount, 1);
    ledger.workerConsumed = zeros(config.workerCount, 1);
    ledger.workerStolen = zeros(config.workerCount, 1);
    ledger.workerReceived = zeros(config.workerCount, 1);

    % === Validation State ===
    ledger.conservationViolations = 0;
    ledger.negativeBalanceViolations = 0;
    ledger.accountingViolations = 0;
    ledger.invalidTransfers = 0;

    % === Error Tracking ===
    ledger.lastError = '';
    ledger.errorHistory = {};
    ledger.eventLogFull = false;

    % === Flow Accounting Sums ===
    % Track total cycles flowing through each operation type for analysis
    ledger.systemDepletionSum = 0;      % Total allocated from system
    ledger.kernelConsumptionSum = 0;    % Total consumed by kernels
    ledger.returnToSystemSum = 0;       % Total returned to system

    % === Underflow/Overflow Tracking ===
    ledger.underflowAttempts = 0;       % Attempts to consume/transfer beyond balance
    ledger.doubleAllocationAttempts = 0; % Attempts to over-allocate per worker
    ledger.partialReturnFailures = 0;   % Failed return operations

    % === Zero-Operation Counts ===
    % Track no-op operations for optimization detection
    ledger.zeroAllocations = 0;
    ledger.zeroConsumptions = 0;
    ledger.zeroTransfers = 0;
    ledger.zeroReturns = 0;
    ledger.selfTransfers = 0;

    % === Per-Worker Return Tracking ===
    % Track cycles returned by each worker (complements consumed/stolen/received)
    ledger.workerReturned = zeros(config.workerCount, 1);

    % === Allocation History ===
    % Track allocation records for deactivation on consumption/return
    ledger.allocationHistory = [];
    ledger.maxConcurrentAllocPerWorker = 16;  % Safety limit

    % === Metadata ===
    ledger.creationTime = datetime('now');
    ledger.experimentId = config.experimentId;
    ledger.seed = config.seed;
    ledger.config = config;

    % === Internal State ===
    ledger.isValid = true;
    ledger.lastValidationTime = datetime('now');

end
