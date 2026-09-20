% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

classdef TestInvariant < matlab.unittest.TestCase

    properties
        config
        ledger
        queues
    end

    methods(TestMethodSetup)
        function setup(testCase)
            addpath(genpath('../src'));
            addpath(genpath('../config'));

            testCase.config = defaultConfig();
            testCase.config.workerCount = 4;
            testCase.config.totalInitialCycles = 1e6;

            % Create ledger
            testCase.ledger = ledger.create(testCase.config.totalInitialCycles, testCase.config);

            % Create queues
            testCase.queues = struct();
            testCase.queues.type = 'FIFO';
            testCase.queues.workerQueues = repmat(struct(...
                'tasks', [], 'taskCount', 0), testCase.config.workerCount, 1);
            testCase.queues.taskLocation = zeros(10000, 1);
            testCase.queues.nextTaskId = uint64(1);
            testCase.queues.totalEnqueued = 0;
            testCase.queues.totalDequeued = 0;
            testCase.queues.eventCount = 0;
            testCase.queues.maxEvents = 1e6;
        end
    end

    methods(Test)

        function testI1CycleConservation(testCase)
            % Test I1: Cycle Conservation
            [testCase.ledger, ~] = ledger.allocate(testCase.ledger, uint32(1), 100000);
            [testCase.ledger, ~] = ledger.allocate(testCase.ledger, uint32(2), 200000);

            [pass, diag] = invariant.cycleConservation(testCase.ledger);

            testCase.verifyTrue(pass);
            testCase.verifyEqual(diag.difference, 0);
            testCase.verifyEqual(diag.totalInitialCycles, testCase.config.totalInitialCycles);
        end

        function testI1ConservationViolation(testCase)
            % Test I1 detects violation
            testCase.ledger.allocatedCycles = 1000;
            testCase.ledger.availableCycles = 1000;
            % Total = 2000, but should be 1e6

            [pass, diag] = invariant.cycleConservation(testCase.ledger);

            testCase.verifyFalse(pass);
            testCase.verifyNotEqual(diag.difference, 0);
        end

        function testI2NonnegativeBalance(testCase)
            % Test I2: Nonnegative Balances
            [testCase.ledger, ~] = ledger.allocate(testCase.ledger, uint32(1), 50000);

            [pass, diag] = invariant.nonnegativeBalance(testCase.ledger);

            testCase.verifyTrue(pass);
            testCase.verifyEqual(diag.negativeBalanceCount, 0);
        end

        function testI2NegativeBalanceDetection(testCase)
            % Force negative balance and detect it
            testCase.ledger.workerCycles(1) = -1000; % Violate I2

            [pass, diag] = invariant.nonnegativeBalance(testCase.ledger);

            testCase.verifyFalse(pass);
            testCase.verifyGreater(diag.negativeBalanceCount, 0);
        end

        function testI3QueueIntegrity(testCase)
            % Test I3: Queue Integrity
            task1 = struct('taskId', 1, 'priority', 0);
            task2 = struct('taskId', 2, 'priority', 0);
            task3 = struct('taskId', 3, 'priority', 0);

            [testCase.queues, ~] = scheduler.enqueue(testCase.queues, uint32(1), task1);
            [testCase.queues, ~] = scheduler.enqueue(testCase.queues, uint32(2), task2);
            [testCase.queues, ~] = scheduler.enqueue(testCase.queues, uint32(3), task3);

            [pass, diag] = invariant.queueIntegrity(testCase.queues);

            testCase.verifyTrue(pass);
            testCase.verifyEqual(diag.duplicateTaskCount, 0);
            testCase.verifyEqual(diag.totalTasksInQueues, 3);
        end

        function testI4ReplayConsistency(testCase)
            % Test I4: Replay Consistency
            [testCase.ledger, ~] = ledger.allocate(testCase.ledger, uint32(1), 50000);
            [testCase.ledger, ~] = ledger.consume(testCase.ledger, uint32(1), 10000);

            snap1 = ledger.snapshot(testCase.ledger);

            % Replay
            [ledger_replayed, match, diag] = ledger.replay(testCase.ledger.events, testCase.config);
            snap2 = ledger.snapshot(ledger_replayed);

            [pass, diag_inv4] = invariant.replayConsistency(snap1, snap2);

            testCase.verifyTrue(pass);
            testCase.verifyTrue(diag_inv4.cyclesMatch);
        end

        function testI6LatencyBound(testCase)
            % Test I6: Latency Bound
            % Create mock workers
            workers = repmat(struct(...
                'taskStartTime', 0, ...
                'taskCompletionTime', 0), 4, 1);

            for i = 1:4
                workers(i).taskStartTime = i * 100;
                workers(i).taskCompletionTime = i * 100 + 500;
            end

            [pass, diag] = invariant.latencyBound(testCase.ledger, workers, testCase.config);

            testCase.verifyNotEmpty(diag.maxLatency);
            testCase.verifyGreaterThanOrEqual(diag.maxLatency, 0);
        end

        function testI8RecursionBound(testCase)
            % Test I8: Recursion Bound
            % Create mock tree
            root.nodeId = 1;
            root.depth = 0;
            root.children = {};

            [pass, diag] = invariant.recursionBound(root, testCase.config);

            testCase.verifyTrue(pass);
            testCase.verifyEqual(diag.maxDepthReached, 0);
            testCase.verifyEqual(diag.totalNodes, 1);
        end

        function testAssertAllInvariants(testCase)
            % Test combined invariant checking
            [testCase.ledger, ~] = ledger.allocate(testCase.ledger, uint32(1), 50000);

            [all_pass, results] = invariant.assertInvariant(...
                testCase.ledger, testCase.queues, testCase.config);

            testCase.verifyTrue(all_pass);
            testCase.verifyTrue(results.I1_pass);
            testCase.verifyTrue(results.I2_pass);
            testCase.verifyTrue(results.I3_pass);
        end

        function testInvariantFailureHandling(testCase)
            % Force invariant failure
            testCase.config.failOnInvariantViolation = true;
            testCase.ledger.workerCycles(1) = -100; % Violate I2

            testCase.assertError(...
                @() invariant.assertInvariant(testCase.ledger, testCase.queues, testCase.config), ...
                'MATLAB:runtime:errAtLine');
        end

        function testConservationAfterStealing(testCase)
            % I1 must hold after stealing
            [testCase.ledger, ~] = ledger.allocate(testCase.ledger, uint32(1), 100000);
            [testCase.ledger, ~] = ledger.allocate(testCase.ledger, uint32(2), 100000);

            % Perform steal
            [testCase.ledger, success, ~] = ledger.transfer(...
                testCase.ledger, uint32(1), uint32(2), 10000);

            testCase.verifyTrue(success);

            % Check conservation
            [pass, diag] = invariant.cycleConservation(testCase.ledger);
            testCase.verifyTrue(pass);
        end

        function testNonnegativeAfterConsumption(testCase)
            % I2 must hold after consumption
            [testCase.ledger, ~] = ledger.allocate(testCase.ledger, uint32(1), 50000);
            [testCase.ledger, success, ~] = ledger.consume(testCase.ledger, uint32(1), 30000);

            testCase.verifyTrue(success);

            % Check nonnegative
            [pass, diag] = invariant.nonnegativeBalance(testCase.ledger);
            testCase.verifyTrue(pass);
            testCase.verifyGreaterThanOrEqual(testCase.ledger.workerCycles(1), 0);
        end

    end

end
