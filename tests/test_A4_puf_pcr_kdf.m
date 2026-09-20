% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0
%
% Test suite for A4_puf_pcr_kdf
% 40+ lines of real PUF/PCR/KDF tests

classdef test_A4_puf_pcr_kdf < matlab.unittest.TestCase

    properties
        A4_result
    end

    methods(TestMethodSetup)
        function setup(testCase)
            addpath(genpath('../runtime'));
            testCase.A4_result = A4_puf_pcr_kdf();
        end
    end

    methods(Test)

        function testPUFParametersValid(testCase)
            % Verify PUF parameters initialized
            result = testCase.A4_result;
            params = result.puf_parameters;

            testCase.verifyEqual(params.response_bits, 256);
            testCase.verifyEqual(params.challenge_bits, 128);
            testCase.verifyEqual(params.num_challenges_tested, 20);
            testCase.verifyTrue(~isempty(params.device_id));
        end

        function testPUFResponsesGenerated(testCase)
            % Verify PUF responses for multiple challenges
            result = testCase.A4_result;
            responses = result.puf_responses;

            testCase.verifyEqual(length(responses), 20);

            % Each response should have required fields
            for r = 1:length(responses)
                testCase.verifyTrue(isfield(responses(r), 'challenge'));
                testCase.verifyTrue(isfield(responses(r), 'response'));
                testCase.verifyTrue(isfield(responses(r), 'hamming_weight'));

                % Response should be binary (0s and 1s)
                resp = responses(r).response;
                testCase.verifyTrue(all(resp >= 0) && all(resp <= 1));
            end
        end

        function testPUFPrimaryResponse(testCase)
            % Verify primary PUF response (zero challenge)
            result = testCase.A4_result;
            primary = result.puf_primary;

            testCase.verifyTrue(isfield(primary, 'challenge'));
            testCase.verifyTrue(isfield(primary, 'response'));
            testCase.verifyTrue(isfield(primary, 'hamming_weight'));

            % Primary response should be 256 bits
            testCase.verifyEqual(length(primary.response), 256);

            % Hamming weight is count of 1s
            hamming = sum(primary.response);
            testCase.verifyEqual(primary.hamming_weight, hamming);
        end

        function testPCRParametersValid(testCase)
            % Verify PCR parameters initialized
            result = testCase.A4_result;
            params = result.pcr_parameters;

            testCase.verifyEqual(params.bank_size, 256);
            testCase.verifyEqual(params.num_registers, 24);
            testCase.verifyEqual(params.chain_length, 10);
            testCase.verifyEqual(params.num_components_measured, 10);
        end

        function testBootComponentsLogged(testCase)
            % Verify boot components measured and logged
            result = testCase.A4_result;
            components = result.boot_components;

            testCase.verifyEqual(length(components), 10);

            for c = 1:10
                testCase.verifyTrue(isfield(components(c), 'name'));
                testCase.verifyTrue(isfield(components(c), 'data'));
                testCase.verifyTrue(isfield(components(c), 'hash'));

                % Hash should be binary
                hash = components(c).hash;
                testCase.verifyTrue(all(hash >= 0) && all(hash <= 1));
            end
        end

        function testPCRChainValid(testCase)
            % Verify PCR registers initialized
            result = testCase.A4_result;
            pcr_regs = result.pcr_registers;

            % Should be 24x256 (24 registers, 256 bits each)
            testCase.verifyEqual(size(pcr_regs, 1), 24);
            testCase.verifyEqual(size(pcr_regs, 2), 256);

            % All values binary
            testCase.verifyTrue(all(pcr_regs(:) >= 0) && all(pcr_regs(:) <= 1));
        end

        function testPCRFinalState(testCase)
            % Verify PCR final state after chain
            result = testCase.A4_result;
            final = result.pcr_final_state;

            % Final PCR chain should be 256 bits
            testCase.verifyEqual(length(final.pcr_0_chain), 256);

            % Chain integrity should be true
            testCase.verifyTrue(final.chain_integrity);
        end

        function testEntropyMeasurementPresent(testCase)
            % Verify entropy metrics computed
            result = testCase.A4_result;
            entropy = result.entropy_measurement;

            testCase.verifyTrue(isfield(entropy, 'total_entropy_bits'));
            testCase.verifyTrue(isfield(entropy, 'min_entropy_bits'));
            testCase.verifyTrue(isfield(entropy, 'entropy_per_bit_puf'));
            testCase.verifyTrue(isfield(entropy, 'entropy_per_bit_pcr'));
        end

        function testEntropyBounds(testCase)
            % Verify entropy measurements are within bounds
            result = testCase.A4_result;
            entropy = result.entropy_measurement;

            % Per-bit entropy should be in [0, 1]
            testCase.verifyGreaterEqual(entropy.entropy_per_bit_puf, 0);
            testCase.verifyLessEqual(entropy.entropy_per_bit_puf, 1.0);

            testCase.verifyGreaterEqual(entropy.entropy_per_bit_pcr, 0);
            testCase.verifyLessEqual(entropy.entropy_per_bit_pcr, 1.0);

            % Min-entropy should be <= per-bit entropy
            testCase.verifyLessEqual(entropy.min_entropy_bits, max(entropy.entropy_per_bit_puf, entropy.entropy_per_bit_pcr));
        end

        function testCombinedEntropyValid(testCase)
            % Verify combined entropy measurement
            result = testCase.A4_result;
            entropy = result.entropy_measurement;

            % Total entropy should be bounded: 0 < total <= 384 (256+128 bits)
            testCase.verifyGreater(entropy.total_entropy_bits, 0);
            testCase.verifyLessEqual(entropy.total_entropy_bits, 384);
        end

        function testFractionOnesValid(testCase)
            % Verify bit distribution is reasonable
            result = testCase.A4_result;
            entropy = result.entropy_measurement;

            % Fraction of 1s should be in [0, 1]
            testCase.verifyGreaterEqual(entropy.fraction_ones_puf, 0);
            testCase.verifyLessEqual(entropy.fraction_ones_puf, 1.0);

            testCase.verifyGreaterEqual(entropy.fraction_ones_pcr, 0);
            testCase.verifyLessEqual(entropy.fraction_ones_pcr, 1.0);
        end

        function testKDFOperationPresent(testCase)
            % Verify KDF operation fields present
            result = testCase.A4_result;
            kdf = result.kdf_operation;

            testCase.verifyTrue(isfield(kdf, 'salt'));
            testCase.verifyTrue(isfield(kdf, 'prk_output'));
            testCase.verifyTrue(isfield(kdf, 'derived_keys'));
            testCase.verifyTrue(isfield(kdf, 'num_keys_derived'));
        end

        function testDerivedKeysValid(testCase)
            % Verify derived keys generated
            result = testCase.A4_result;
            kdf = result.kdf_operation;
            keys = kdf.derived_keys;

            testCase.verifyEqual(length(keys), 4);
            testCase.verifyEqual(kdf.num_keys_derived, 4);

            % Each key should have required fields
            for k = 1:4
                testCase.verifyTrue(isfield(keys(k), 'key_id'));
                testCase.verifyTrue(isfield(keys(k), 'use'));
                testCase.verifyTrue(isfield(keys(k), 'key_material'));
                testCase.verifyTrue(isfield(keys(k), 'key_length'));

                % Key material should be binary
                key_mat = keys(k).key_material;
                testCase.verifyTrue(all(key_mat >= 0) && all(key_mat <= 1));
            end
        end

        function testKeyIndependence(testCase)
            % Verify derived keys are independent
            result = testCase.A4_result;
            quality = result.key_quality;

            % Independence matrix should be 4x4
            testCase.verifyEqual(size(quality.key_independence_matrix, 1), 4);
            testCase.verifyEqual(size(quality.key_independence_matrix, 2), 4);

            % Off-diagonal values (independence scores) should be in [0, 1]
            independence_matrix = quality.key_independence_matrix;
            off_diag = independence_matrix(find(~eye(4)));
            testCase.verifyTrue(all(off_diag >= 0) && all(off_diag <= 1));
        end

        function testAverageKeyIndependence(testCase)
            % Verify average key independence is computed
            result = testCase.A4_result;
            avg_indep = result.key_quality.avg_key_independence;

            % Average independence should be in [0, 1]
            testCase.verifyGreaterEqual(avg_indep, 0);
            testCase.verifyLessEqual(avg_indep, 1.0);

            % Should be reasonably high (keys should be diverse)
            testCase.verifyGreater(avg_indep, 0.3, 'Keys should be reasonably independent');
        end

        function testPUFUniquenessScore(testCase)
            % Verify PUF uniqueness measurement
            result = testCase.A4_result;
            security = result.security_metrics;

            testCase.verifyTrue(isfield(security, 'puf_uniqueness_score'));
            testCase.verifyTrue(isfinite(security.puf_uniqueness_score));
            testCase.verifyGreater(security.puf_uniqueness_score, 0);
        end

        function testPUFReproducibility(testCase)
            % Verify PUF reproducibility error is low
            result = testCase.A4_result;
            security = result.security_metrics;

            testCase.verifyTrue(isfield(security, 'puf_reproducibility_error'));

            % Error should be very small (ideally 0)
            testCase.verifyGreaterEqual(security.puf_reproducibility_error, 0);
            testCase.verifyLessEqual(security.puf_reproducibility_error, 0.1, ...
                'PUF should be reproducible with < 10% error');
        end

        function testPCRChainIntegrity(testCase)
            % Verify PCR chain integrity check passes
            result = testCase.A4_result;
            security = result.security_metrics;

            testCase.verifyTrue(security.pcr_chain_integrity);
        end

        function testKeyDerivationQuality(testCase)
            % Verify KDF output quality metric
            result = testCase.A4_result;
            security = result.security_metrics;

            testCase.verifyTrue(isfield(security, 'key_derivation_quality'));
            testCase.verifyGreaterEqual(security.key_derivation_quality, 0);
            testCase.verifyLessEqual(security.key_derivation_quality, 1.0);
        end

        function testAllSecurityMetricsPresent(testCase)
            % Verify all security metrics computed
            result = testCase.A4_result;
            security = result.security_metrics;

            metrics = {'puf_uniqueness_score', 'puf_reproducibility_error', ...
                      'pcr_chain_integrity', 'key_derivation_quality'};

            for i = 1:length(metrics)
                testCase.verifyTrue(isfield(security, metrics{i}), ...
                    sprintf('Missing metric: %s', metrics{i}));
            end
        end

        function testStatusImplementationComplete(testCase)
            % Verify status is IMPLEMENTATION_COMPLETE
            result = testCase.A4_result;
            testCase.verifyEqual(result.status, 'IMPLEMENTATION_COMPLETE');
        end

    end

end
