% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [ledger, steal_events] = boundedPolicy(ledger, config)
    % Bounded cycle stealing policy
    % Only steal when load difference exceeds threshold

    arguments
        ledger struct
        config struct
    end

    steal_events = [];
    event_count = 0;

    % Get load metrics
    loads = ledger.workerCycles;
    meanLoad = mean(loads);

    % Try stealing
    for thief = 1:ledger.workerCount
        thiefLoad = ledger.workerCycles(thief);

        % Only steal if significantly underloaded
        if thiefLoad < meanLoad * (1 - config.stealThreshold)

            % Find most overloaded donor
            [maxLoad, donor] = max(loads);

            if maxLoad > meanLoad * (1 + config.stealThreshold) && donor ~= thief

                % Calculate steal amount
                loadDiff = maxLoad - thiefLoad;
                cycles_to_steal = min(config.maxStealPerOperation, ...
                    floor(loadDiff / 2));

                if cycles_to_steal > 0
                    [ledger, success, eventId] = ledger.transfer(...
                        uint32(donor), uint32(thief), cycles_to_steal);

                    if success
                        event_count = event_count + 1;
                        steal_events(event_count).eventId = eventId;
                        steal_events(event_count).thief = thief;
                        steal_events(event_count).donor = donor;
                        steal_events(event_count).cycles = cycles_to_steal;
                        steal_events(event_count).policy = 'bounded';
                        steal_events(event_count).reason = sprintf(...
                            'load_diff=%.0f', loadDiff);
                    end
                end
            end
        end
    end

end
