% Test suite for F2_boot_gate
classdef test_F2_boot < matlab.unittest.TestCase
    properties
        F2_result
    end
    methods(TestMethodSetup)
        function setup(testCase)
            addpath(genpath('../runtime'));
            testCase.F2_result = F2_boot_gate();
        end
    end
    methods(Test)
        function testStatusClaimed(testCase)
            result = testCase.F2_result;
            testCase.verifyEqual(result.status, 'CLAIMED');
        end
        function testStateSize(testCase)
            result = testCase.F2_result;
            testCase.verifyEqual(result.state_size, 32);
        end
        function testDeterministicSeed(testCase)
            result = testCase.F2_result;
            testCase.verifyEqual(result.deterministic_seed, 42);
        end
        function testReproducibilityMatches(testCase)
            result = testCase.F2_result;
            testCase.verifyEqual(result.reproducibility_matches, result.F2_result.F2_result);
        end
        function testReproducibilityVerified(testCase)
            result = testCase.F2_result;
            testCase.verifyTrue(result.reproducibility_verified);
        end
        function testBootOutputSize(testCase)
            result = testCase.F2_result;
            testCase.verifyEqual(length(result.boot_output_ref), result.state_size);
        end
        function testBootOutputNonZero(testCase)
            result = testCase.F2_result;
            testCase.verifyGreater(sum(abs(result.boot_output_ref)), 0);
        end
        function testEntropyNormalized(testCase)
            result = testCase.F2_result;
            entropy = result.entropy_normalized;
            testCase.verifyGreaterEqual(entropy, 0);
            testCase.verifyLessEqual(entropy, 1.0);
        end
        function testI5DeterminismPass(testCase)
            result = testCase.F2_result;
            testCase.verifyTrue(result.i5_pass);
        end
        function testKSTestPValue(testCase)
            result = testCase.F2_result;
            p = result.ks_test_p_value;
            testCase.verifyGreaterEqual(p, 0);
            testCase.verifyLessEqual(p, 1.0);
        end
        function testSeedSensitivity(testCase)
            result = testCase.F2_result;
            testCase.verifyGreater(result.unique_inits, 3);
        end
        function testAllOutputsSameShape(testCase)
            result = testCase.F2_result;
            outputs = result.all_outputs;
            testCase.verifyEqual(size(outputs, 2), result.state_size);
        end
    end
end
