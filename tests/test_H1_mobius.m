% Test suite for H1_mobius_obligations
classdef test_H1_mobius < matlab.unittest.TestCase
    properties
        H1_result
    end
    methods(TestMethodSetup)
        function setup(testCase)
            addpath(genpath('../runtime'));
            testCase.H1_result = H1_mobius_obligations();
        end
    end
    methods(Test)
        function testStatusOpen(testCase)
            result = testCase.H1_result;
            testCase.verifyEqual(result.status, 'OPEN');
        end
        function testObligationCount(testCase)
            result = testCase.H1_result;
            testCase.verifyEqual(result.obligation_count, 3);
        end
        function testOB1DataPresent(testCase)
            result = testCase.H1_result;
            testCase.verifyTrue(isfield(result, 'OB1_data'));
        end
        function testOB2DataPresent(testCase)
            result = testCase.H1_result;
            testCase.verifyTrue(isfield(result, 'OB2_data'));
        end
        function testOB3DataPresent(testCase)
            result = testCase.H1_result;
            testCase.verifyTrue(isfield(result, 'OB3_data'));
        end
        function testFixedPointsComputed(testCase)
            result = testCase.H1_result;
            testCase.verifyGreater(length(result.OB1_data.all_fixed_points), 0);
        end
        function testConvergenceDataPresent(testCase)
            result = testCase.H1_result;
            data = result.OB2_data;
            testCase.verifyGreaterEqual(data.converged_points, 0);
        end
        function testTraceValuesComputed(testCase)
            result = testCase.H1_result;
            testCase.verifyGreater(length(result.OB3_data.trace_values), 0);
        end
    end
end
