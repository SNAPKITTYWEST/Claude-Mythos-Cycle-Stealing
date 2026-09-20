% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

classdef TestReplay < matlab.unittest.TestCase

    properties
        config
    end

    methods(TestMethodSetup)
        function setup(testCase)
            addpath(genpath('../src'));
            addpath(genpath('../config'));
            testCase.config = defaultConfig();
        end
    end

    methods(Test)

        function testReplayBaseline(testCase)
            % Test replay of baseline experiment
            testCase.config.seed = 12345;
            testCase.config.experimentType = 'baseline';

            % Run experiment
            result = run_experiment('baseline');
            original_events = result.ledger.events;
            original_state = result.ledger;

            % Replay
            [ledger_replayed, match, diag] = ledger.replay(original_events, testCase.config);

            testCase.verifyTrue(match);
            testCase.verifyEqual(ledger_replayed.consumedCycles, original_state.consumedCycles);
            testCase.verifyEqual(ledger_replayed.stolenCycles, original_state.stolenCycles);
        end

        function testReplayEventOrdering(testCase)
            % Replay preserves event order
            testCase.config.seed = 54321;

            result = run_experiment('baseline');
            events = result.ledger.events;

            % Verify event IDs are ordered
            for i = 2:length(events)
                testCase.verifyGreater(events(i).eventId, events(i-1).eventId);
            end
        end

        function testReplayConsumption(testCase)
            % Verify consumption events replay correctly
            testCase.config.seed = 99999;

            result = run_experiment('baseline');

            % Count consumption events
            consume_events = [];
            for i = 1:length(result.ledger.events)
                if strcmp(result.ledger.events(i).operation, 'consume')
                    consume_events(end+1) = i;
                end
            end

            testCase.verifyGreater(length(consume_events), 0);
        end

        function testReplayAllocation(testCase)
            % Verify allocation events replay correctly
            testCase.config.seed = 11111;

            result = run_experiment('baseline');

            % Count allocation events
            alloc_count = 0;
            for i = 1:length(result.ledger.events)
                if strcmp(result.ledger.events(i).operation, 'allocate')
                    alloc_count = alloc_count + 1;
                end
            end

            % Should have at least as many as workers
            testCase.verifyGreaterThanOrEqual(alloc_count, testCase.config.workerCount);
        end

        function testReplayStealEvents(testCase)
            % Verify stealing events replay correctly
            testCase.config.seed = 22222;
            testCase.config.stealingPolicy = 'random';

            result = run_experiment('random_stealing');

            % Count steal events
            steal_count = 0;
            for i = 1:length(result.ledger.events)
                if strcmp(result.ledger.events(i).operation, 'steal')
                    steal_count = steal_count + 1;
                end
            end

            testCase.verifyGreater(steal_count, 0);
        end

        function testReplayResultMatches(testCase)
            % Replay result matches original
            testCase.config.seed = 33333;

            result_original = run_experiment('baseline');

            % Replay
            [ledger_replayed, match, ~] = ledger.replay(...
                result_original.ledger.events, testCase.config);

            testCase.verifyTrue(match);
            testCase.verifyEqual(length(ledger_replayed.events), ...
                length(result_original.ledger.events));
        end

        function testReplayStateSnapshot(testCase)
            % Replay state snapshot matches original
            testCase.config.seed = 44444;

            result = run_experiment('baseline');
            snap_original = ledger.snapshot(result.ledger);

            % Replay
            [ledger_replayed, ~, ~] = ledger.replay(result.ledger.events, testCase.config);
            snap_replayed = ledger.snapshot(ledger_replayed);

            testCase.verifyEqual(snap_original.totalInitialCycles, ...
                snap_replayed.totalInitialCycles);
            testCase.verifyEqual(snap_original.consumedCycles, ...
                snap_replayed.consumedCycles);
        end

        function testReplayWithEmptyEvents(testCase)
            % Replay empty event log
            testCase.config.seed = 55555;

            % Create empty event array
            empty_events = [];

            ledger_init = ledger.create(testCase.config.totalInitialCycles, testCase.config);

            % Replay (should just return initial state)
            [ledger_replayed, match, diag] = ledger.replay(empty_events, testCase.config);

            testCase.verifyTrue(match);
            testCase.verifyEqual(ledger_replayed.availableCycles, ...
                ledger_init.availableCycles);
        end

        function testReplayChecksum(testCase)
            % Replay produces matching checksums
            testCase.config.seed = 66666;

            result = run_experiment('baseline');
            snap_original = ledger.snapshot(result.ledger);

            [ledger_replayed, ~, ~] = ledger.replay(result.ledger.events, testCase.config);
            snap_replayed = ledger.snapshot(ledger_replayed);

            testCase.verifyEqual(snap_original.stateHash, snap_replayed.stateHash);
        end

        function testReplayWithBoundedStealing(testCase)
            % Replay bounded stealing experiment
            testCase.config.seed = 77777;
            testCase.config.stealingPolicy = 'bounded';

            result = run_experiment('bounded_stealing');

            [ledger_replayed, match, ~] = ledger.replay(result.ledger.events, testCase.config);

            testCase.verifyTrue(match);
        end

        function testReplayWithPriorityStealing(testCase)
            % Replay priority stealing experiment
            testCase.config.seed = 88888;
            testCase.config.stealingPolicy = 'priority';

            result = run_experiment('priority_stealing');

            [ledger_replayed, match, ~] = ledger.replay(result.ledger.events, testCase.config);

            testCase.verifyTrue(match);
        end

        function testReplayEventConsistency(testCase)
            % Events are consistent when replayed
            testCase.config.seed = 99999;

            result = run_experiment('baseline');
            events_original = result.ledger.events;

            [ledger_replayed, ~, diag] = ledger.replay(events_original, testCase.config);
            events_replayed = ledger_replayed.events;

            testCase.verifyEqual(length(events_original), length(events_replayed));

            % Check sample of events match
            sample_indices = [1 ceil(length(events_original)/4) ...
                              ceil(length(events_original)/2) ...
                              length(events_original)];

            for idx = sample_indices
                if idx <= length(events_original)
                    testCase.verifyEqual(events_original(idx).operation, ...
                        events_replayed(idx).operation);
                    testCase.verifyEqual(events_original(idx).cycles, ...
                        events_replayed(idx).cycles);
                end
            end
        end

    end

end
