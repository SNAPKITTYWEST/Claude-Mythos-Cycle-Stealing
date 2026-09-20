% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [ledger, steal_events] = priorityPolicy(ledger, config)
    % Priority-based cycle stealing policy
    % Select donors and thieves based on priority metrics

    arguments
        ledger struct
        config struct
    end

    steal_events = [];
    event_count = 0;

    % Compute priority scores (lower cycles = higher priority to steal)
    priorities = 1.0 ./ (ledger.workerCycles + 1);
    [sortedPriorities, sortedWorkers] = sort(priorities, 'descend');

    % Top workers are highest priority to steal FOR
    % Try stealing FROM workers with lowest priority
    maxSteals = config.maxStealersPerRound;
    steals_done = 0;

    for i = 1:min(maxSteals, ledger.workerCount)
        thief = sortedWorkers(i); % Highest priority recipient
        thiefLoad = ledger.workerCycles(thief);

        % Find eligible donor (lowest priority worker with cycles)
        for j = ledger.workerCount:-1:1
            if j == thief
                continue;
            end

            donor = sortedWorkers(j);
            donorLoad = ledger.workerCycles(donor);

            if donorLoad > config.maxStealPerOperation && thiefLoad < donorLoad
                cycles_to_steal = min(config.maxStealPerOperation, ...
                    floor((donorLoad - thiefLoad) / 3));

                if cycles_to_steal > 0
                    [ledger, success, eventId] = ledger.transfer(...
                        uint32(donor), uint32(thief), cycles_to_steal);

                    if success
                        event_count = event_count + 1;
                        steal_events(event_count).eventId = eventId;
                        steal_events(event_count).thief = thief;
                        steal_events(event_count).donor = donor;
                        steal_events(event_count).cycles = cycles_to_steal;
                        steal_events(event_count).policy = 'priority';
                        steals_done = steals_done + 1;
                        break;
                    end
                end
            end
        end

        if steals_done >= maxSteals
            break;
        end
    end

end
