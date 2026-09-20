% Test suite for G1_aead_key_commitment
classdef test_G1_aead < matlab.unittest.TestCase
    properties
        G1_result
    end
    methods(TestMethodSetup)
        function setup(testCase)
            addpath(genpath('../runtime'));
            testCase.G1_result = G1_aead_key_commitment();
        end
    end
    methods(Test)
        function testStatusClaimed(testCase)
            result = testCase.G1_result;
            testCase.verifyEqual(result.status, 'CLAIMED');
        end
        function testKeySizeBits(testCase)
            result = testCase.G1_result;
            testCase.verifyEqual(result.key_size_bits, 256);
        end
        function testNonceSizeBits(testCase)
            result = testCase.G1_result;
            testCase.verifyEqual(result.nonce_size_bits, 128);
        end
        function testTagSizeBits(testCase)
            result = testCase.G1_result;
            testCase.verifyEqual(result.tag_size_bits, 128);
        end
        function testBindingVerified(testCase)
            result = testCase.G1_result;
            testCase.verifyTrue(result.binding_verified);
        end
        function testCommitmentValuesSize(testCase)
            result = testCase.G1_result;
            testCase.verifyGreater(size(result.commitment_values, 1), 0);
            testCase.verifyGreater(size(result.commitment_values, 2), 0);
        end
        function testUniqueCommitments(testCase)
            result = testCase.G1_result;
            testCase.verifyGreater(result.unique_commitments, 0);
        end
        function testCollisionRate(testCase)
            result = testCase.G1_result;
            testCase.verifyGreaterEqual(result.collision_rate, 0);
            testCase.verifyLessEqual(result.collision_rate, 1.0);
        end
        function testHammingDistances(testCase)
            result = testCase.G1_result;
            testCase.verifyGreater(length(result.hamming_distances), 0);
        end
        function testMeanHammingDistance(testCase)
            result = testCase.G1_result;
            testCase.verifyGreater(result.mean_hamming_distance, 50);  % should be ~128/2 for good hash
        end
    end
end
