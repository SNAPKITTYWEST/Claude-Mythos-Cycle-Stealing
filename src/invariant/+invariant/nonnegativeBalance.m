% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [pass, diagnostic] = nonnegativeBalance(ledger)
    % I2: Nonnegative Balances
    % All worker cycle balances >= 0

    diagnostic = struct();
    diagnostic.invariant = 'I2_NonnegativeBalance';

    negCount = sum(ledger.workerCycles < 0);
    pass = (negCount == 0);

    diagnostic.workerBalances = ledger.workerCycles;
    diagnostic.negativeBalanceCount = negCount;
    diagnostic.minBalance = min(ledger.workerCycles);
    diagnostic.pass = pass;

    if ~pass
        negative_ids = find(ledger.workerCycles < 0);
        diagnostic.message = sprintf('Workers %s have negative balances', ...
            sprintf('%d ', negative_ids));
    end

end
