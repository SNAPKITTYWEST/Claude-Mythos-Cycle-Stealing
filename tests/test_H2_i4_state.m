% Test suite for H2_i4_full_state
classdef test_H2_i4_state < matlab.unittest.TestCase
    properties
        H2_result
    end
    methods(TestMethodSetup)
        function setup(testCase)
            addpath(genpath('../runtime'));
            testCase.H2_result = H2_i4_full_state();
        end
    end
    methods(Test)
        function testStatusOpen(testCase)
            result = testCase.H2_result;
            testCase.verifyEqual(result.status, 'OPEN');
        end
        function testSpaceDimension(testCase)
            result = testCase.H2_result;
            testCase.verifyEqual(result.space_dimension, 8);
        end
        function testTestStateCount(testCase)
            result = testCase.H2_result;
            testCase.verifyGreater(result.num_test_states, 0);
        end
        function testI4ValuesComputed(testCase)
            result = testCase.H2_result;
            testCase.verifyEqual(length(result.i4_values), result.num_test_states);
        end
        function testCollisionCountNonNegative(testCase)
            result = testCase.H2_result;
            testCase.verifyGreaterEqual(result.collision_count_test, 0);
        end
        function testLevelSetSizesPresent(testCase)
            result = testCase.H2_result;
            testCase.verifyGreater(length(result.level_set_sizes), 0);
        end
        function testCounterexamplesArray(testCase)
            result = testCase.H2_result;
            testCase.verifyTrue(iscell(result.counterexamples_found) || isempty(result.counterexamples_found));
        end
    end
end
