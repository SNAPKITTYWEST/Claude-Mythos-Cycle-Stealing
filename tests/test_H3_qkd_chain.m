% Test suite for H3_qkd_i4_chain_open
classdef test_H3_qkd_chain < matlab.unittest.TestCase
    properties
        H3_result
    end
    methods(TestMethodSetup)
        function setup(testCase)
            addpath(genpath('../runtime'));
            testCase.H3_result = H3_qkd_i4_chain_open();
        end
    end
    methods(Test)
        function testStatusOpen(testCase)
            result = testCase.H3_result;
            testCase.verifyEqual(result.status, 'OPEN');
        end
        function testSecurityParameter(testCase)
            result = testCase.H3_result;
            testCase.verifyEqual(result.security_parameter, 128);
        end
        function testPrivacyAmpRounds(testCase)
            result = testCase.H3_result;
            testCase.verifyGreater(result.privacy_amp_rounds, 0);
        end
        function testQKDStatesPresent(testCase)
            result = testCase.H3_result;
            testCase.verifyTrue(isfield(result, 'qkd_states'));
        end
        function testI4ValuesArray(testCase)
            result = testCase.H3_result;
            testCase.verifyGreater(length(result.i4_values), 0);
        end
        function testTotalLoss(testCase)
            result = testCase.H3_result;
            testCase.verifyGreaterEqual(result.total_loss, 0);
        end
        function testLossThreshold(testCase)
            result = testCase.H3_result;
            testCase.verifyGreater(result.loss_threshold, 0);
        end
        function testChainFailuresNonNegative(testCase)
            result = testCase.H3_result;
            testCase.verifyGreaterEqual(result.chain_failures, 0);
        end
    end
end
