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
    ledger.invalidTransfers = 0;

    % === Metadata ===
    ledger.creationTime = datetime('now');
    ledger.experimentId = config.experimentId;
    ledger.seed = config.seed;
    ledger.config = config;

    % === Internal State ===
     ledger.isValid = true;
    ledger.lastValidationTime = datetime('now');

end
