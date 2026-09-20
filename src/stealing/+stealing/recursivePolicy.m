% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [ledger, steal_events] = recursivePolicy(ledger, config, depth)
    % Recursive cycle stealing policy
    % Allow stealing to trigger additional scheduling decisions

    arguments
        ledger struct
        config struct
        depth (1,1) {mustBeNonnegative} = 0
    end

    steal_events = [];
    event_count = 0;

    % Base case: max depth reached
    if depth >= config.stealingDepthLimit
        return;
    end

    % Apply bounded stealing at this level
    [ledger, base_steals] = stealing.boundedPolicy(ledger, config);
    steal_events = base_steals;
    event_count = length(base_steals);

    % If stealing occurred, recursively try additional stealing
    if event_count > 0 && depth < config.stealingDepthLimit - 1

        % Trigger recursive stealing with slightly modified config
        config_modified = config;
        config_modified.stealThreshold = config.stealThreshold * 0.8; % More aggressive

        [ledger, recursive_steals] = stealing.recursivePolicy(...
            ledger, config_modified, depth + 1);

        % Append recursive events
        if ~isempty(recursive_steals)
            for i = 1:length(recursive_steals)
                steal_events(end+1) = recursive_steals(i);
            end
        end
    end

end
