% Test suite for H4_mixcolumns_linearity
classdef test_H4_mixcolumns < matlab.unittest.TestCase
    properties
        H4_result
    end
    methods(TestMethodSetup)
        function setup(testCase)
            addpath(genpath('../runtime'));
            testCase.H4_result = H4_mixcolumns_linearity();
        end
    end
    methods(Test)
        function testStatusOpen(testCase)
            result = testCase.H4_result;
            testCase.verifyEqual(result.status, 'OPEN');
        end
        function testStateBytes(testCase)
            result = testCase.H4_result;
            testCase.verifyEqual(result.state_bytes, 4);
        end
        function testViolationCount(testCase)
            result = testCase.H4_result;
            % MixColumns should NOT be GF(2)-linear, so we expect violations
            testCase.verifyGreater(result.violation_count, 0);
        end
        function testLinearityPassRate(testCase)
            result = testCase.H4_result;
            rate = result.linearity_pass_rate;
            testCase.verifyGreaterEqual(rate, 0);
            testCase.verifyLessEqual(rate, 1.0);
        end
        function testViolationsArray(testCase)
            result = testCase.H4_result;
            testCase.verifyTrue(iscell(result.linearity_violations) || isstruct(result.linearity_violations));
        end
        function testSubspaceCount(testCase)
            result = testCase.H4_result;
            testCase.verifyGreaterEqual(result.subspace_preserved_count, 0);
        end
    end
end
