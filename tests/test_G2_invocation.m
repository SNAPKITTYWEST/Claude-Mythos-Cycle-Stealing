% Test suite for G2_invocation_limit
classdef test_G2_invocation < matlab.unittest.TestCase
    properties
        G2_result
    end
    methods(TestMethodSetup)
        function setup(testCase)
            addpath(genpath('../runtime'));
            testCase.G2_result = G2_invocation_limit();
        end
    end
    methods(Test)
        function testStatusVerified(testCase)
            result = testCase.G2_result;
            testCase.verifyEqual(result.status, 'VERIFIED_COMPUTATIONAL');
        end
        function testLimitValue(testCase)
            result = testCase.G2_result;
            testCase.verifyEqual(result.limit, 2^32);
        end
        function testTestCasesCount(testCase)
            result = testCase.G2_result;
            testCase.verifyEqual(length(result.test_cases), 3);
        end
        function testTestCasesValues(testCase)
            result = testCase.G2_result;
            expected = [2^32-1, 2^32, 2^32+1];
            testCase.verifyEqual(result.test_cases, expected);
        end
        function testInvocationAllowed(testCase)
            result = testCase.G2_result;
            allowed = result.invocation_allowed;
            testCase.verifyTrue(allowed(1));  % limit-1 allowed
            testCase.verifyFalse(allowed(2)); % limit denied
            testCase.verifyFalse(allowed(3)); % limit+1 denied
        end
        function testPolicyCorrect(testCase)
            result = testCase.G2_result;
            testCase.verifyTrue(result.policy_correct);
        end
        function testInvocationSequenceLength(testCase)
            result = testCase.G2_result;
            testCase.verifyGreater(length(result.invocation_sequence), 0);
        end
        function testStatusSequenceLength(testCase)
            result = testCase.G2_result;
            testCase.verifyGreater(length(result.status_sequence), 0);
        end
    end
end
