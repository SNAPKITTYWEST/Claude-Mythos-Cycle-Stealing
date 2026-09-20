% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

classdef TestStealing < matlab.unittest.TestCase

    properties
        config
        ledger
    end

    methods(TestMethodSetup)
        function setup(testCase)
            addpath(genpath('../src'));
            addpath(genpath('../config'));

            testCase.config = defaultConfig();
            testCase.config.workerCount = 4;
            testCase.config.totalInitialCycles = 1e6;

            testCase.ledger = ledger.create(testCase.config.totalInitialCycles, testCase.config);

            % Allocate cycles to workers
            for i = 1:testCase.config.workerCount
                [testCase.ledger, ~] = ledger.allocate(testCase.ledger, uint32(i), 250000);
            end
        end
    end

    methods(Test)

        function testRandomStealing(testCase)
            % Test random stealing policy
            rng_state = utils.deterministicSeed(uint64(123));
            testCase.config.stealingPolicy = 'random';
            testCase.config.stealingProbability = 0.5;

            [ledger_result, steal_events] = stealing.randomPolicy(...
                testCase.ledger, testCase.config, rng_state);

            % May or may not steal depending on RNG
            testCase.verifyNotEmpty(steal_events);

            % Invariant must hold: total cycles unchanged
            total_before = testCase.ledger.totalInitialCycles;
            total_after = ledger_result.totalInitialCycles;
            testCase.verifyEqual(total_before, total_after);
        end

        function testBoundedStealing(testCase)
            % Test bounded stealing policy
            testCase.config.stealingPolicy = 'bounded';
            testCase.config.stealThreshold = 0.3;

            % Create imbalanced state
            [testCase.ledger, ~] = ledger.consume(testCase.ledger, uint32(1), 100000);
            [testCase.ledger, ~] = ledger.allocate(testCase.ledger, uint32(1), 50000);

            [ledger_result, steal_events] = stealing.boundedPolicy(...
                testCase.ledger, testCase.config);

            % Should have attempted stealing
            testCase.verifyNotEmpty(steal_events);
        end

        function testPriorityStealing(testCase)
            % Test priority stealing policy
            testCase.config.stealingPolicy = 'priority';
            testCase.config.maxStealersPerRound = 2;

            % Create imbalance
            [testCase.ledger, ~] = ledger.consume(testCase.ledger, uint32(1), 100000);
            [testCase.ledger, ~] = ledger.consume(testCase.ledger, uint32(2), 50000);

            [ledger_result, steal_events] = stealing.priorityPolicy(...
                testCase.ledger, testCase.config);

            % Check steals limited to max
            testCase.verifyLessEqual(length(steal_events), testCase.config.maxStealersPerRound);
        end

        function testRecursiveStealing(testCase)
            % Test recursive stealing policy
            testCase.config.stealingPolicy = 'recursive';
            testCase.config.stealingDepthLimit = 2;

            [ledger_result, steal_events] = stealing.recursivePolicy(...
                testCase.ledger, testCase.config, 0);

            % Should maintain conservation law
            total = ledger_result.totalInitialCycles;
            allocated = ledger_result.allocatedCycles;
            available = ledger_result.availableCycles;

            testCase.verifyEqual(total, allocated + available);
        end

        function testStealingConservation(testCase)
            % Verify steals don't create/destroy cycles
            total_before = testCase.ledger.allocatedCycles + testCase.ledger.availableCycles;

            [ledger_result, ~] = stealing.boundedPolicy(...
                testCase.ledger, testCase.config);

            total_after = ledger_result.allocatedCycles + ledger_result.availableCycles;

            testCase.verifyEqual(total_before, total_after);
        end

        function testStealNonnegativity(testCase)
            % Verify steals never create negative balances
            [ledger_result, steal_events] = stealing.randomPolicy(...
                testCase.ledger, testCase.config, utils.deterministicSeed(uint64(456)));

            [pass, diag] = invariant.nonnegativeBalance(ledger_result);
            testCase.verifyTrue(pass);

            testCase.verifyEqual(min(ledger_result.workerCycles), 0 ...
                , 'Should have non-negative or zero minimum');
        end

        function testPolicyFactory(testCase)
            % Test policy factory dispatch
            rng_state = utils.deterministicSeed(uint64(789));

            % Test each policy through factory
            policies = {'random', 'bounded', 'priority', 'recursive', 'none'};

            for p = 1:length(policies)
                testCase.config.stealingPolicy = policies{p};
                [result, events] = stealing.policyFactory(...
                    testCase.ledger, testCase.config, rng_state);

                % All should maintain conservation
                total = result.allocatedCycles + result.availableCycles;
                testCase.verifyEqual(total, testCase.ledger.totalInitialCycles);
            end
        end

        function testStealEventLogging(testCase)
            % Verify steal events are properly logged
            [ledger_result, steal_events] = stealing.boundedPolicy(...
                testCase.ledger, testCase.config);

            if ~isempty(steal_events)
                for i = 1:length(steal_events)
                    event = steal_events(i);
                    testCase.verifyGreater(event.eventId, 0);
                    testCase.verifyGreater(event.cycles, 0);
                    testCase.verifyNotEmpty(event.policy);
                end
            end
        end

    end

end
