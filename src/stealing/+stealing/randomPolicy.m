% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [ledger, steal_events] = randomPolicy(ledger, config, rng_state)
    % Random cycle stealing policy
    % Probabilistically attempt steals based on RNG

    arguments
        ledger struct
        config struct
        rng_state (1,1) struct
    end

    steal_events = [];
    event_count = 0;

    % Restore RNG state for determinism
    rng(rng_state);

    % Try stealing from each worker
    for thief = 1:ledger.workerCount
        % Check if thief has low cycles
        if ledger.workerCycles(thief) < config.stealThreshold * config.cyclesPerWorker

            % Probabilistically attempt steal
            if rand() < config.stealingProbability

                % Find random donor with cycles
                eligible_donors = [];
                for donor = 1:ledger.workerCount
                    if donor ~= thief && ledger.workerCycles(donor) > config.maxStealPerOperation
                        eligible_donors(end+1) = donor;
                    end
                end

                if ~isempty(eligible_donors)
                    donor = eligible_donors(randi(length(eligible_donors)));
                    cycles_to_steal = min(config.maxStealPerOperation, ...
                        floor(ledger.workerCycles(donor) / 2));

                    if cycles_to_steal > 0
                        [ledger, success, eventId] = ledger.transfer(uint32(donor), uint32(thief), cycles_to_steal);

                        if success
                            event_count = event_count + 1;
                            steal_events(event_count).eventId = eventId;
                            steal_events(event_count).thief = thief;
                            steal_events(event_count).donor = donor;
                            steal_events(event_count).cycles = cycles_to_steal;
                            steal_events(event_count).policy = 'random';
                        end
                    end
                end
            end
        end
    end

end
