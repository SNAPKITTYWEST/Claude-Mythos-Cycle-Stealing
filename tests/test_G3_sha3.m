% Test suite for G3_sha3_policy
classdef test_G3_sha3 < matlab.unittest.TestCase
    properties
        G3_result
    end
    methods(TestMethodSetup)
        function setup(testCase)
            addpath(genpath('../runtime'));
            testCase.G3_result = G3_sha3_policy();
        end
    end
    methods(Test)
        function testStatusClaimed(testCase)
            result = testCase.G3_result;
            testCase.verifyEqual(result.status, 'CLAIMED');
        end
        function testHashAlgorithm(testCase)
            result = testCase.G3_result;
            testCase.verifyEqual(result.hash_algorithm, 'SHA3-512');
        end
        function testOutputBits(testCase)
            result = testCase.G3_result;
            testCase.verifyEqual(result.output_bits, 512);
        end
        function testOutputBytes(testCase)
            result = testCase.G3_result;
            testCase.verifyEqual(result.output_bytes, 64);
        end
        function testAllCorrectLength(testCase)
            result = testCase.G3_result;
            testCase.verifyTrue(result.all_correct_length);
        end
        function testAllNonZero(testCase)
            result = testCase.G3_result;
            testCase.verifyTrue(result.all_nonzero);
        end
        function testHashDeterminism(testCase)
            result = testCase.G3_result;
            testCase.verifyTrue(result.hash_determinism);
        end
        function testPolicyPass(testCase)
            result = testCase.G3_result;
            testCase.verifyTrue(result.policy_pass);
        end
        function testUniqueHashes(testCase)
            result = testCase.G3_result;
            testCase.verifyGreater(result.unique_hashes, result.total_comparisons * 0.95);
        end
        function testByteDistribution(testCase)
            result = testCase.G3_result;
            testCase.verifyGreater(length(result.byte_distribution), 0);
        end
    end
end
