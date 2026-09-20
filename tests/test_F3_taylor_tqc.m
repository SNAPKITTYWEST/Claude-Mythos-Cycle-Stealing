% Test suite for F3_taylor_tqc
classdef test_F3_taylor_tqc < matlab.unittest.TestCase
    properties
        F3_result
    end
    methods(TestMethodSetup)
        function setup(testCase)
            addpath(genpath('../runtime'));
            testCase.F3_result = F3_taylor_tqc();
        end
    end
    methods(Test)
        function testStatusVerified(testCase)
            result = testCase.F3_result;
            testCase.verifyEqual(result.status, 'VERIFIED_COMPUTATIONAL');
        end
        function testTaylorOrder(testCase)
            result = testCase.F3_result;
            testCase.verifyEqual(result.taylor_order, 8);
        end
        function testYangBaxterthreshold(testCase)
            result = testCase.F3_result;
            testCase.verifyEqual(result.yang_baxter_threshold, 1e-8);
        end
        function testYangBaxtherAllPass(testCase)
            result = testCase.F3_result;
            testCase.verifyTrue(result.all_yb_pass);
        end
        function testUnitarityAllPass(testCase)
            result = testCase.F3_result;
            testCase.verifyTrue(result.all_unitarity_pass);
        end
        function testMaxResidue(testCase)
            result = testCase.F3_result;
            testCase.verifyLess(result.max_residual, result.yang_baxter_threshold);
        end
        function testMeanResidue(testCase)
            result = testCase.F3_result;
            testCase.verifyGreater(result.mean_residual, 0);
            testCase.verifyLess(result.mean_residual, result.yang_baxter_threshold);
        end
        function testThetaValues(testCase)
            result = testCase.F3_result;
            testCase.verifyGreater(length(result.theta_values), 0);
        end
        function testUnitarityErrorsSize(testCase)
            result = testCase.F3_result;
            testCase.verifyEqual(length(result.unitarity_errors), length(result.theta_values));
        end
        function testUnitarityErrorsPositive(testCase)
            result = testCase.F3_result;
            testCase.verifyGreaterEqual(min(result.unitarity_errors), 0);
        end
        function testYBResidualsArray(testCase)
            result = testCase.F3_result;
            testCase.verifyGreater(length(result.yang_baxter_residuals), 0);
        end
        function testResidualsBounded(testCase)
            result = testCase.F3_result;
            residuals = result.yang_baxter_residuals;
            testCase.verifyLess(max(residuals), 1e-6);
        end
    end
end
