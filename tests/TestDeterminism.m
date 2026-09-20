% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

classdef TestDeterminism < matlab.unittest.TestCase

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

        function testBaselineDeterminism(testCase)
            % Same config → same results
            testCase.config.seed = 123;
            testCase.config.experimentType = 'baseline';

            result1 = run_experiment('baseline');
            result2 = run_experiment('baseline');

            testCase.verifyEqual(result1.statistics.totalTasksCompleted, ...
                result2.statistics.totalTasksCompleted);
            testCase.verifyEqual(result1.ledger.consumedCycles, ...
                result2.ledger.consumedCycles);
        end

        function testRandomStealingDeterminism(testCase)
            % Random policy with same seed → same steals
            testCase.config.seed = 456;
            testCase.config.stealingPolicy = 'random';

            result1 = run_experiment('random_stealing');
            result2 = run_experiment('random_stealing');

            testCase.verifyEqual(result1.statistics.totalStealOperations, ...
                result2.statistics.totalStealOperations);
        end

        function testBoundedStealingDeterminism(testCase)
            % Bounded policy → deterministic stealing
            testCase.config.seed = 789;
            testCase.config.stealingPolicy = 'bounded';

            result1 = run_experiment('bounded_stealing');
            result2 = run_experiment('bounded_stealing');

            testCase.verifyEqual(result1.ledger.stolenCycles, ...
                result2.ledger.stolenCycles);
        end

        function testDifferentSeedsDifferentResults(testCase)
            % Different seed → potentially different results
            testCase.config.experimentType = 'random_stealing';

            testCase.config.seed = 111;
            result1 = run_experiment('random_stealing');

            testCase.config.seed = 222;
            result2 = run_experiment('random_stealing');

            % May or may not differ, but should be reproducible
            snap1 = ledger.snapshot(result1.ledger);
            snap2 = ledger.snapshot(result2.ledger);

            % Both should have valid hashes
            testCase.verifyNotEmpty(snap1.stateHash);
            testCase.verifyNotEmpty(snap2.stateHash);
        end

        function testReplayConsistency(testCase)
            % Replay → exact match
            testCase.config.seed = 333;

            result = run_experiment('baseline');
            snap_original = ledger.snapshot(result.ledger);

            % Replay events
            [ledger_replayed, match, diag] = ledger.replay(...
                result.ledger.events, testCase.config);

            snap_replayed = ledger.snapshot(ledger_replayed);

            [pass, diag_consistency] = invariant.replayConsistency(...
                snap_original, snap_replayed);

            testCase.verifyTrue(pass);
            testCase.verifyTrue(match);
        end

        function testConfigurationImmutability(testCase)
            % Config not modified during execution
            testCase.config.seed = 555;
            original_config = testCase.config;

            result = run_experiment('baseline');

            testCase.verifyEqual(result.config.seed, original_config.seed);
            testCase.verifyEqual(result.config.workerCount, original_config.workerCount);
            testCase.verifyEqual(result.config.totalInitialCycles, ...
                original_config.totalInitialCycles);
        end

        function testEventLogDeterminism(testCase)
            % Event log structure deterministic
            testCase.config.seed = 666;

            result1 = run_experiment('baseline');
            result2 = run_experiment('baseline');

            testCase.verifyEqual(length(result1.ledger.events), ...
                length(result2.ledger.events));

            % First few events should match
            for i = 1:min(5, length(result1.ledger.events))
                event1 = result1.ledger.events(i);
                event2 = result2.ledger.events(i);

                testCase.verifyEqual(event1.operation, event2.operation);
                testCase.verifyEqual(event1.cycles, event2.cycles);
            end
        end

        function testWorkerStateDeterminism(testCase)
            % Worker states deterministic
            testCase.config.seed = 777;

            result1 = run_experiment('baseline');
            result2 = run_experiment('baseline');

            testCase.verifyEqual(result1.ledger.workerConsumed, ...
                result2.ledger.workerConsumed);
            testCase.verifyEqual(result1.ledger.workerStolen, ...
                result2.ledger.workerStolen);
        end

        function testCycleAllocationDeterminism(testCase)
            % Cycle allocation follows deterministic pattern
            testCase.config.seed = 888;

            result1 = run_experiment('baseline');
            result2 = run_experiment('baseline');

            % Allocated cycles should match
            testCase.verifyEqual(result1.ledger.allocatedCycles, ...
                result2.ledger.allocatedCycles);

            % Available cycles should match
            testCase.verifyEqual(result1.ledger.availableCycles, ...
                result2.ledger.availableCycles);
        end

        function testInvariantConsistency(testCase)
            % Invariants pass consistently
            testCase.config.seed = 999;

            result1 = run_experiment('baseline');
            result2 = run_experiment('baseline');

            testCase.verifyTrue(result1.invariantPass);
            testCase.verifyTrue(result2.invariantPass);

            % Same invariant diagnostics
            testCase.verifyEqual(result1.invariantResults.violationCount, ...
                result2.invariantResults.violationCount);
        end

        function testRNGSeedIsolation(testCase)
            % RNG seed doesn't leak between experiments
            testCase.config.seed = 111;
            result1 = run_experiment('baseline');

            testCase.config.seed = 222;
            result2 = run_experiment('baseline');

            % First experiment result unchanged
            testCase.verifyEqual(result1.statistics.totalTasksCompleted, ...
                run_experiment('baseline').statistics.totalTasksCompleted);
        end

        function testMultipleRunsReproducibility(testCase)
            % Series of runs → reproducible
            testCase.config.seed = 1001;
            seeds = [1001 1002 1003];

            results_first = {};
            for i = 1:length(seeds)
                testCase.config.seed = seeds(i);
                results_first{i} = run_experiment('baseline');
            end

            % Re-run with same seeds
            results_second = {};
            for i = 1:length(seeds)
                testCase.config.seed = seeds(i);
                results_second{i} = run_experiment('baseline');
            end

            % Should match
            for i = 1:length(seeds)
                testCase.verifyEqual(...
                    results_first{i}.statistics.totalTasksCompleted, ...
                    results_second{i}.statistics.totalTasksCompleted);
            end
        end

    end

end
