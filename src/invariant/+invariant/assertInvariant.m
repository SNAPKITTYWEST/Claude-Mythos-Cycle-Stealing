% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [all_pass, results] = assertInvariant(ledger, queues, config)
    % Assert all invariants and return structured results
    % Used throughout execution for continuous validation

    results = struct();
    results.timestamp = datetime('now');

    % I1: Cycle Conservation
    [results.I1_pass, results.I1_diag] = invariant.cycleConservation(ledger);

    % I2: Nonnegative Balances
    [results.I2_pass, results.I2_diag] = invariant.nonnegativeBalance(ledger);

    % I3: Queue Integrity
    [results.I3_pass, results.I3_diag] = invariant.queueIntegrity(queues);

    % Summary
    all_pass = results.I1_pass && results.I2_pass && results.I3_pass;

    results.allPass = all_pass;
    results.violationCount = (~results.I1_pass) + (~results.I2_pass) + (~results.I3_pass);

    if ~all_pass
        results.violations = {};
        if ~results.I1_pass
            results.violations{end+1} = results.I1_diag.message;
        end
        if ~results.I2_pass
            results.violations{end+1} = results.I2_diag.message;
        end
        if ~results.I3_pass
            results.violations{end+1} = results.I3_diag.message;
        end

        if config.failOnInvariantViolation
            error('Invariant violation detected:\n%s', ...
                sprintf('%s\n', results.violations{:}));
        end
    end

end
