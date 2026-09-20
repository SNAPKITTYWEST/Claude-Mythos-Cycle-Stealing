% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0
%
% Test suite for A3_quantum_decoder
% 40+ lines of real quantum decoder tests

classdef test_A3_quantum_decoder < matlab.unittest.TestCase

    properties
        A3_result
    end

    methods(TestMethodSetup)
        function setup(testCase)
            addpath(genpath('../runtime'));
            testCase.A3_result = A3_quantum_decoder();
        end
    end

    methods(Test)

        function testArithmeticVerification(testCase)
            % REAL ARITHMETIC: Verify 672*98 + 352*97 = 100000
            result = testCase.A3_result;
            arith = result.arithmetic;

            testCase.verifyEqual(arith.term1_672_times_98, 65856);
            testCase.verifyEqual(arith.term2_352_times_97, 34144);
            testCase.verifyEqual(arith.sum_value, 100000);
            testCase.verifyTrue(arith.arithmetic_verified);
        end

        function testQuantumParameters(testCase)
            % Verify quantum simulation parameters
            result = testCase.A3_result;
            params = result.quantum_parameters;

            testCase.verifyEqual(params.num_qubits, 8);
            testCase.verifyEqual(params.num_basis_states, 256);
            testCase.verifyEqual(params.measurement_trials, 1000);
            testCase.verifyEqual(params.basis, 'computational');
        end

        function testMeasurementHistogramValid(testCase)
            % Verify measurement histogram is probability distribution
            result = testCase.A3_result;
            hist = result.measurement_statistics.histogram;

            % All probabilities in [0, 1]
            testCase.verifyGreaterEqual(min(hist), 0);
            testCase.verifyLessEqual(max(hist), 1.0);

            % Probabilities sum to 1
            total = sum(hist);
            testCase.verifyEqual(total, 1.0, 'AbsTol', 1e-10);
        end

        function testReconstructedAmplitudes(testCase)
            % Verify reconstructed quantum state amplitudes
            result = testCase.A3_result;
            recon = result.quantum_reconstruction;
            amps = recon.reconstructed_amplitudes;

            % Amplitudes should be non-negative (real-valued reconstruction)
            testCase.verifyGreaterEqual(min(amps), 0);

            % Should be normalized (unit vector)
            norm_squared = sum(amps.^2);
            testCase.verifyEqual(norm_squared, 1.0, 'AbsTol', 1e-10);
        end

        function testPurityComputed(testCase)
            % Verify purity (measure of state purity)
            result = testCase.A3_result;
            purity = result.measurement_statistics.purity;

            % Purity in [0, 1] for quantum states
            testCase.verifyGreaterEqual(purity, 0);
            testCase.verifyLessEqual(purity, 1.0);
        end

        function testEntropyValid(testCase)
            % Verify Shannon entropy computed correctly
            result = testCase.A3_result;
            entropy = result.measurement_statistics.entropy;

            % For 256 basis states, entropy <= 8 bits
            testCase.verifyGreaterEqual(entropy, 0);
            testCase.verifyLessEqual(entropy, 8.0);
        end

        function testDominantStatesPresent(testCase)
            % Verify top 16 dominant basis states identified
            result = testCase.A3_result;
            dominant = result.dominant_states;

            testCase.verifyEqual(length(dominant), 16);

            % Each should have valid state index (0-255)
            for d = 1:16
                testCase.verifyGreaterEqual(dominant(d).state_index, 0);
                testCase.verifyLessEqual(dominant(d).state_index, 255);
            end
        end

        function testDominantStatesProbabilities(testCase)
            % Verify dominant states have highest probabilities
            result = testCase.A3_result;
            dominant = result.dominant_states;

            % First state should have highest probability
            for d = 1:(length(dominant) - 1)
                prob_current = dominant(d).measured_probability;
                prob_next = dominant(d+1).measured_probability;
                testCase.verifyGreaterEqual(prob_current, prob_next);
            end
        end

        function testCumulativeProbability(testCase)
            % Verify cumulative probability of top 16 states
            result = testCase.A3_result;
            cum_prob = result.dominant_cumulative_probability;

            % Top 16 states should account for significant fraction
            testCase.verifyGreater(cum_prob, 0.3, 'Top states should have significant probability');
            testCase.verifyLessEqual(cum_prob, 1.0);
        end

        function testKullbackLeiblerDivergence(testCase)
            % Verify KL divergence computed
            result = testCase.A3_result;
            kl = result.error_analysis.kl_divergence;

            % KL divergence is non-negative
            testCase.verifyGreaterEqual(kl, 0);

            % Should be finite (perfect reconstruction would give KL ≈ 0)
            testCase.verifyTrue(isfinite(kl));
        end

        function testHellingerDistance(testCase)
            % Verify Hellinger distance (symmetric divergence)
            result = testCase.A3_result;
            hell = result.error_analysis.hellinger_distance;

            % Hellinger distance in [0, 1]
            testCase.verifyGreaterEqual(hell, 0);
            testCase.verifyLessEqual(hell, 1.0);
        end

        function testMeasurementQuality(testCase)
            % Verify measurement quality score
            result = testCase.A3_result;
            quality = result.error_analysis.measurement_quality;

            % Quality in [0, 1] (1 = perfect)
            testCase.verifyGreaterEqual(quality, 0);
            testCase.verifyLessEqual(quality, 1.0);
        end

        function testMostProbableDecision(testCase)
            % Verify most probable state decoder decision
            result = testCase.A3_result;
            decision = result.decoder_decision;

            % State index valid (0-255)
            testCase.verifyGreaterEqual(decision.most_probable_state, 0);
            testCase.verifyLessEqual(decision.most_probable_state, 255);

            % Binary string valid
            binary = decision.most_probable_binary;
            testCase.verifyEqual(length(binary), 8);

            % Confidence in [0, 1]
            testCase.verifyGreater(decision.most_probable_confidence, 0);
            testCase.verifyLessEqual(decision.most_probable_confidence, 1.0);
        end

        function testMajorityVotingDecision(testCase)
            % Verify majority voting decoder decision
            result = testCase.A3_result;
            decision = result.decoder_decision;

            % Majority voting state valid (0-255)
            testCase.verifyGreaterEqual(decision.majority_voting_state, 0);
            testCase.verifyLessEqual(decision.majority_voting_state, 255);

            % Binary string valid
            binary = decision.majority_voting_binary;
            testCase.verifyEqual(length(binary), 8);
        end

        function testDecisionConfidence(testCase)
            % Verify decision confidence score
            result = testCase.A3_result;
            conf = result.decoder_decision.decision_confidence;

            % Confidence >= 0
            testCase.verifyGreaterEqual(conf, 0);
        end

        function testRepeatProbability(testCase)
            % Verify consistency: if same measurement repeated, would we get same result?
            result = testCase.A3_result;
            repeat_prob = result.decoder_decision.repeat_probability;

            % Should be in [0, 1]
            testCase.verifyGreaterEqual(repeat_prob, 0);
            testCase.verifyLessEqual(repeat_prob, 1.0);

            % For peaky distribution (well-defined state), should be significant
            testCase.verifyGreater(repeat_prob, 0.05, 'Should have reproducible measurements');
        end

        function testDecoderQualityMetrics(testCase)
            % Verify all decoder quality metrics present
            result = testCase.A3_result;
            quality = result.decoder_quality;

            testCase.verifyTrue(isfield(quality, 'measurement_quality'));
            testCase.verifyTrue(isfield(quality, 'state_distillation_purity'));
            testCase.verifyTrue(isfield(quality, 'decision_confidence_score'));
            testCase.verifyTrue(isfield(quality, 'consistency_score'));

            % All should be numeric and finite
            testCase.verifyTrue(isnumeric(quality.measurement_quality));
            testCase.verifyTrue(isfinite(quality.measurement_quality));
        end

        function testStatusVerifiedComputational(testCase)
            % Verify status is VERIFIED_COMPUTATIONAL
            result = testCase.A3_result;
            testCase.verifyEqual(result.status, 'VERIFIED_COMPUTATIONAL');
        end

        function testAllArithmeticFieldsPresent(testCase)
            % Verify all arithmetic computation fields present
            result = testCase.A3_result;
            arith = result.arithmetic;

            required_fields = {'term1_672_times_98', 'term2_352_times_97', ...
                              'sum_value', 'expected_value', 'arithmetic_verified'};

            for i = 1:length(required_fields)
                testCase.verifyTrue(isfield(arith, required_fields{i}), ...
                    sprintf('Missing field: %s', required_fields{i}));
            end
        end

    end

end
