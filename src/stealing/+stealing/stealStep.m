% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [ledger, steal_events] = stealStep(ledger, config, rng_state)
    % Execute one stealing step according to the selected policy

    arguments
        ledger struct
        config struct
        rng_state (1,1) struct
    end

    [ledger, steal_events] = stealing.policyFactory(ledger, config, rng_state);

end
