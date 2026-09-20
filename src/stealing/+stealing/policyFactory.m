% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [ledger, steal_events] = policyFactory(ledger, config, rng_state)
    % Factory function to apply the selected stealing policy
    % Dispatches to appropriate policy implementation

    arguments
        ledger struct
        config struct
        rng_state (1,1) struct
    end

    steal_events = [];

    switch config.stealingPolicy
        case 'none'
            % No stealing
            steal_events = [];

        case 'random'
            [ledger, steal_events] = stealing.randomPolicy(ledger, config, rng_state);

        case 'bounded'
            [ledger, steal_events] = stealing.boundedPolicy(ledger, config);

        case 'priority'
            [ledger, steal_events] = stealing.priorityPolicy(ledger, config);

        case 'recursive'
            [ledger, steal_events] = stealing.recursivePolicy(ledger, config, 0);

        otherwise
            error('Unknown stealing policy: %s', config.stealingPolicy);
    end

end
