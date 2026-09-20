% Test suite for F4_watson_identity
classdef test_F4_watson < matlab.unittest.TestCase
    properties
        F4_result
    end
    methods(TestMethodSetup)
        function setup(testCase)
            addpath(genpath('../runtime'));
            testCase.F4_result = F4_watson_identity();
        end
    end
    methods(Test)
        function testStatusVerified(testCase)
            result = testCase.F4_result;
            testCase.verifyEqual(result.status, 'VERIFIED_COMPUTATIONAL');
        end
        function testScalesCorrect(testCase)
            result = testCase.F4_result;
            testCase.verifyEqual(result.scale_incorrect, 0.75);
            testCase.verifyEqual(result.scale_corrected, 1.0);
        end
        function testTestValuesCount(testCase)
            result = testCase.F4_result;
            testCase.verifyGreater(length(result.test_values), 0);
        end
        function testIncorrectResultsSize(testCase)
            result = testCase.F4_result;
            testCase.verifyEqual(length(result.incorrect_results), length(result.test_values));
        end
        function testCorrectedResultsSize(testCase)
            result = testCase.F4_result;
            testCase.verifyEqual(length(result.corrected_results), length(result.test_values));
        end
        function testErrorsZero(testCase)
            result = testCase.F4_result;
            testCase.verifyLess(result.max_error, 1e-10);
        end
        function testCorrectionFactor(testCase)
            result = testCase.F4_result;
            factor = result.mean_correction_factor;
            expected = 4/3;
            testCase.verifyEqual(factor, expected, 'AbsTol', 1e-10);
        end
        function testCorrectedEqualsIdentity(testCase)
            result = testCase.F4_result;
            % Corrected should be the original values
            for i = 1:length(result.test_values)
                expected = result.test_values(i);
                actual = result.corrected_results(i);
                testCase.verifyEqual(actual, expected, 'AbsTol', 1e-10);
            end
        end
        function testIncorrectScaled(testCase)
            result = testCase.F4_result;
            for i = 1:length(result.test_values)
                expected = 0.75 * result.test_values(i);
                actual = result.incorrect_results(i);
                testCase.verifyEqual(actual, expected, 'AbsTol', 1e-10);
            end
        end
    end
end
