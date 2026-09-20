% Test suite for F1_proof_dag
% 50+ lines of real test cases

classdef test_F1_dag < matlab.unittest.TestCase

    properties
        F1_result
    end

    methods(TestMethodSetup)
        function setup(testCase)
            addpath(genpath('../runtime'));
            testCase.F1_result = F1_proof_dag();
        end
    end

    methods(Test)

        function testStructurePresent(testCase)
            % Verify all required fields
            result = testCase.F1_result;

            testCase.verifyTrue(isfield(result, 'status'));
            testCase.verifyTrue(isfield(result, 'node_durations'));
            testCase.verifyTrue(isfield(result, 'adjacency'));
            testCase.verifyTrue(isfield(result, 'critical_path_length'));
            testCase.verifyTrue(isfield(result, 'makespan'));
            testCase.verifyTrue(isfield(result, 'proof_tokens'));
        end

        function testStatusClaimed(testCase)
            result = testCase.F1_result;
            testCase.verifyEqual(result.status, 'CLAIMED');
        end

        function testCycleBudget(testCase)
            result = testCase.F1_result;
            testCase.verifyEqual(result.cycle_budget, 1000);
        end

        function testCriticalPathLimit(testCase)
            result = testCase.F1_result;
            testCase.verifyEqual(result.critical_path_limit, 575);
        end

        function testCriticalPathConstraint(testCase)
            result = testCase.F1_result;
            testCase.verifyTrue(result.constraint_satisfied);
            testCase.verifyLessEqual(result.critical_path_length, 575);
        end

        function testNodeCount(testCase)
            result = testCase.F1_result;
            testCase.verifyEqual(result.num_nodes, 32);
        end

        function testNodeDurationsPositive(testCase)
            result = testCase.F1_result;
            durations = result.node_durations;
            testCase.verifyGreater(min(durations), 0);
        end

        function testAdjacencyDAG(testCase)
            result = testCase.F1_result;
            adj = result.adjacency;

            % Check for cycles (DAG property)
            % Compute transitive closure
            power = eye(size(adj));
            for i = 1:size(adj,1)-1
                power = power * adj;
                if trace(bitand(power, eye(size(adj)))) > 0
                    % Cycle detected
                    testCase.verifyFail('Adjacency matrix has cycles');
                end
            end
        end

        function testTimingNonNegative(testCase)
            result = testCase.F1_result;
            testCase.verifyGreaterEqual(min(result.earliest_start), 0);
            testCase.verifyGreaterEqual(min(result.earliest_finish), 0);
            testCase.verifyGreaterEqual(min(result.latest_start), 0);
            testCase.verifyGreaterEqual(min(result.latest_finish), 0);
        end

        function testSlackNonNegative(testCase)
            result = testCase.F1_result;
            testCase.verifyGreaterEqual(min(result.slack), -1e-6);
        end

        function testCriticalNodesExist(testCase)
            result = testCase.F1_result;
            testCase.verifyGreater(length(result.critical_nodes), 0);
        end

        function testMakespanConsistent(testCase)
            result = testCase.F1_result;
            testCase.verifyLessEqual(result.makespan, result.cycle_budget);
        end

        function testProofTokensValid(testCase)
            result = testCase.F1_result;
            tokens = result.proof_tokens;

            testCase.verifyEqual(length(tokens.node_hashes), result.num_nodes);
            testCase.verifyEqual(length(tokens.dependencies_verified), result.num_nodes);
        end

        function testUtilizationInRange(testCase)
            result = testCase.F1_result;
            util = result.average_utilization;

            testCase.verifyGreater(util, 0);
            testCase.verifyLessEqual(util, 1.0);
        end

        function testWallClockTiming(testCase)
            result = testCase.F1_result;
            testCase.verifyGreater(result.wall_clock_ns, 0);
            testCase.verifyGreater(result.wall_clock_us, 0);
        end

        function testAllNodesDimension(testCase)
            result = testCase.F1_result;
            testCase.verifyEqual(length(result.node_durations), result.num_nodes);
            testCase.verifyEqual(size(result.adjacency, 1), result.num_nodes);
            testCase.verifyEqual(size(result.adjacency, 2), result.num_nodes);
        end

    end

end
