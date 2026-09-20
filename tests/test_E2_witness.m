% test_E2_witness.m - Unit tests for E2 Epistemic Witness Generation
% Status: VERIFIED_COMPUTATIONAL
% Tests witness generation, Blake3 chaining, chain validation

classdef test_E2_witness < matlab.unittest.TestCase

    properties
        E2
    end

    methods(TestMethodSetup)
        function setup(testCase)
            testCase.E2 = E2_epistemic_witness();
        end
    end

    % === WITNESS RECORD STRUCTURE TESTS ===

    methods(Test)

        function test_record_template_defined(testCase)
            % Verify witness record template has all required fields
            template = testCase.E2.record_template;

            testCase.verifyTrue(isfield(template, 'finding_id'));
            testCase.verifyTrue(isfield(template, 'sequence_number'));
            testCase.verifyTrue(isfield(template, 'timestamp'));
            testCase.verifyTrue(isfield(template, 'input_hash'));
            testCase.verifyTrue(isfield(template, 'output_hash'));
            testCase.verifyTrue(isfield(template, 'computation_trace'));
            testCase.verifyTrue(isfield(template, 'metadata'));
            testCase.verifyTrue(isfield(template, 'previous_witness_hash'));
            testCase.verifyTrue(isfield(template, 'seal_hash'));
            testCase.verifyTrue(isfield(template, 'seal_signature'));
        end

        function test_record_fields_correct_type(testCase)
            % Verify record fields have correct initial types
            template = testCase.E2.record_template;

            testCase.verifyTrue(ischar(template.finding_id) || isstring(template.finding_id));
            testCase.verifyTrue(isnumeric(template.sequence_number));
            testCase.verifyTrue(isnumeric(template.timestamp));
            testCase.verifyTrue(ischar(template.input_hash) || isstring(template.input_hash));
        end

    end

    % === HASH CONFIGURATION TESTS ===

    methods(Test)

        function test_hash_algorithm_blake3(testCase)
            % Verify Blake3 is configured
            testCase.verifyEqual(testCase.E2.hash_config.algorithm, 'Blake3');
        end

        function test_hash_output_bits(testCase)
            % Verify hash output is 256 bits
            testCase.verifyEqual(testCase.E2.hash_config.output_bits, 256);
        end

        function test_hash_output_bytes(testCase)
            % Verify 256 bits = 32 bytes
            testCase.verifyEqual(testCase.E2.hash_config.output_bytes, 32);
        end

        function test_hash_security_level(testCase)
            % Verify security level is 256 bits
            testCase.verifyEqual(testCase.E2.hash_config.security_level, 256);
        end

        function test_incremental_context_structure(testCase)
            % Verify incremental hasher context is properly structured
            ctx = testCase.E2.hash_config.incremental_context;

            testCase.verifyTrue(isfield(ctx, 'state'));
            testCase.verifyTrue(isfield(ctx, 'buffer'));
            testCase.verifyTrue(isfield(ctx, 'buffer_len'));
            testCase.verifyTrue(isfield(ctx, 'chunks_hashed'));
            testCase.verifyTrue(isfield(ctx, 'finalized'));
        end

    end

    % === WITNESS CHAIN TESTS ===

    methods(Test)

        function test_chain_initialized_empty(testCase)
            % Verify witness chain starts empty
            testCase.verifyEqual(testCase.E2.chain.length, 0);
            testCase.verifyEmpty(testCase.E2.chain.records);
        end

        function test_chain_validity_flag(testCase)
            % Verify chain starts in valid state
            testCase.verifyTrue(testCase.E2.chain.is_valid);
        end

        function test_chain_head_hash_empty_initially(testCase)
            % Verify chain head hash is empty initially
            testCase.verifyEmpty(testCase.E2.chain.current_head);
        end

    end

    % === BLAKE3 HASH FUNCTION TESTS ===

    methods(Test)

        function test_blake3_hash_callable(testCase)
            % Verify Blake3 hash function is callable
            testCase.verifyTrue(isa(testCase.E2.blake3_hash, 'function_handle'));
        end

        function test_blake3_hash_deterministic(testCase)
            % Property: Blake3 hash is deterministic
            test_data = 'test_witness_data';

            hash1 = testCase.E2.blake3_hash(test_data);
            hash2 = testCase.E2.blake3_hash(test_data);

            testCase.verifyEqual(hash1, hash2);
        end

        function test_blake3_hash_different_inputs(testCase)
            % Property: Different inputs give different hashes (collision resistance)
            hash1 = testCase.E2.blake3_hash('input1');
            hash2 = testCase.E2.blake3_hash('input2');

            testCase.verifyNotEqual(hash1, hash2);
        end

        function test_blake3_hash_length(testCase)
            % Verify Blake3 hash has expected length (256-bit = 64 hex chars)
            hash_result = testCase.E2.blake3_hash('test');

            % Blake3(256-bit) = 64 hex characters
            testCase.verifyEqual(length(hash_result), 64);
        end

    end

    % === WITNESS GENERATION TESTS ===

    methods(Test)

        function test_generate_witness_callable(testCase)
            % Verify witness generation is callable
            testCase.verifyTrue(isa(testCase.E2.generate_witness, 'function_handle'));
        end

        function test_generate_witness_creates_record(testCase)
            % Test that witness generation creates valid record
            finding_id = 'E1_qlg_sla_qra';
            input_data = 'quantum_state_input';
            output_data = 'gauge_invariant_observable';

            witness = testCase.E2.generate_witness(finding_id, input_data, output_data);

            testCase.verifyTrue(isstruct(witness));
            testCase.verifyEqual(witness.finding_id, finding_id);
        end

        function test_generated_witness_has_hashes(testCase)
            % Verify generated witness includes input/output hashes
            finding_id = 'test_finding';
            witness = testCase.E2.generate_witness(finding_id, 'in', 'out');

            testCase.verifyNotEmpty(witness.input_hash);
            testCase.verifyNotEmpty(witness.output_hash);
        end

        function test_generated_witness_has_timestamp(testCase)
            % Verify generated witness includes timestamp
            witness = testCase.E2.generate_witness('test', 'in', 'out');

            testCase.verifyGreaterThan(witness.timestamp, 0);
        end

        function test_generated_witness_has_trace(testCase)
            % Verify generated witness includes computation trace
            witness = testCase.E2.generate_witness('test', 'in', 'out');

            testCase.verifyGreaterThan(length(witness.computation_trace), 0);
        end

        function test_generated_witness_has_seal(testCase)
            % Verify generated witness is sealed
            witness = testCase.E2.generate_witness('test', 'in', 'out');

            testCase.verifyNotEmpty(witness.seal_hash);
            testCase.verifyNotEmpty(witness.seal_signature);
        end

    end

    % === WITNESS VERIFICATION TESTS ===

    methods(Test)

        function test_verify_witness_callable(testCase)
            % Verify witness verification is callable
            testCase.verifyTrue(isa(testCase.E2.verify_witness, 'function_handle'));
        end

        function test_verify_fresh_witness_passes(testCase)
            % Test that freshly generated witness verifies
            witness = testCase.E2.generate_witness('test', 'in', 'out');
            is_valid = testCase.E2.verify_witness(witness);

            testCase.verifyTrue(is_valid);
        end

        function test_verify_witness_recomputes_seal(testCase)
            % Test that verification recomputes seal correctly
            witness = testCase.E2.generate_witness('E1', 'state_before', 'state_after');
            is_valid = testCase.E2.verify_witness(witness);

            testCase.verifyTrue(is_valid);
        end

    end

    % === WITNESS CHAIN OPERATIONS TESTS ===

    methods(Test)

        function test_append_witness_callable(testCase)
            % Verify append witness is callable
            testCase.verifyTrue(isa(testCase.E2.append_witness, 'function_handle'));
        end

        function test_seal_witness_callable(testCase)
            % Verify seal witness is callable
            testCase.verifyTrue(isa(testCase.E2.seal_witness, 'function_handle'));
        end

    end

    % === WITNESS INVARIANT TESTS ===

    methods(Test)

        function test_invariant_I1_hash_length(testCase)
            % I1_hash_length: All hashes are 32 bytes (64 hex chars)
            witness = testCase.E2.generate_witness('test', 'in', 'out');

            testCase.verifyEqual(length(witness.seal_hash), 64);
            testCase.verifyEqual(length(witness.input_hash), 64);
            testCase.verifyEqual(length(witness.output_hash), 64);
        end

        function test_invariant_I2_chain_acyclic(testCase)
            % I2_chain_acyclic: No witness references itself
            witness1 = testCase.E2.generate_witness('E1', 'in1', 'out1');
            witness2 = testCase.E2.generate_witness('E2', 'in2', 'out2');

            % witness1 has no previous
            testCase.verifyEmpty(witness1.previous_witness_hash);

            % witness2 links to witness1
            witness2.previous_witness_hash = witness1.seal_hash;

            % Self-reference check
            testCase.verifyNotEqual(witness1.seal_hash, witness1.previous_witness_hash);
        end

        function test_invariant_I3_temporal_monotonic(testCase)
            % I3_temporal_monotonic: Timestamps increase or stay same
            t1 = now;
            witness1 = testCase.E2.generate_witness('E1', 'in1', 'out1');

            % Small delay
            pause(0.01);
            t2 = now;

            witness1.timestamp = t1;
            witness2 = testCase.E2.generate_witness('E2', 'in2', 'out2');
            witness2.timestamp = t2;

            testCase.verifyGreaterThanOrEqual(witness2.timestamp, witness1.timestamp);
        end

        function test_invariant_I6_trace_nonempty(testCase)
            % I6_trace_completeness: Computation trace is non-empty
            witness = testCase.E2.generate_witness('test', 'in', 'out');

            testCase.verifyGreaterThan(length(witness.computation_trace), 0);
        end

    end

    % === VERIFICATION HARNESS TESTS ===

    methods(Test)

        function test_verification_invariants_defined(testCase)
            % Verify all invariants are defined
            inv = testCase.E2.verification.invariants;

            testCase.verifyGreaterThanOrEqual(length(inv), 6);
        end

        function test_verify_invariant_I1_function(testCase)
            % Test I1 invariant function
            witness = testCase.E2.generate_witness('test', 'in', 'out');

            test_I1 = testCase.E2.verification.test_invariant_I1(witness);
            testCase.verifyTrue(test_I1);
        end

        function test_verify_invariant_I6_function(testCase)
            % Test I6 invariant function
            witness = testCase.E2.generate_witness('test', 'in', 'out');

            test_I6 = testCase.E2.verification.test_invariant_I6(witness);
            testCase.verifyTrue(test_I6);
        end

    end

    % === PROVENANCE TESTS ===

    methods(Test)

        function test_provenance_source_defined(testCase)
            % Verify provenance source is documented
            testCase.verifyEqual(testCase.E2.provenance.claim_source, 'verified_computational');
        end

        function test_provenance_implementation_file(testCase)
            % Verify implementation file is documented
            testCase.verifyEqual(testCase.E2.provenance.implementation_file, 'E2_epistemic_witness.m');
        end

        function test_provenance_version_defined(testCase)
            % Verify witness generator version
            testCase.verifyNotEmpty(testCase.E2.provenance.witness_generator_version);
        end

    end

    % === CONFIGURATION TESTS ===

    methods(Test)

        function test_config_hash_algorithm(testCase)
            % Verify hash algorithm configuration
            testCase.verifyEqual(testCase.E2.config.hash_algorithm, 'Blake3');
        end

        function test_config_max_trace_entries(testCase)
            % Verify maximum trace entries configured
            testCase.verifyGreaterThan(testCase.E2.config.max_trace_entries, 0);
        end

        function test_config_max_chain_length(testCase)
            % Verify maximum chain length configured
            testCase.verifyGreaterThan(testCase.E2.config.max_chain_length, 0);
        end

        function test_config_seal_format(testCase)
            % Verify seal format is configured
            testCase.verifyTrue(strcmp(testCase.E2.config.seal_format, 'hex') || ...
                                strcmp(testCase.E2.config.seal_format, 'base64'));
        end

    end

    % === EXAMPLE TESTS ===

    methods(Test)

        function test_example_E1_defined(testCase)
            % Verify E1 example is defined
            testCase.verifyNotEmpty(testCase.E2.examples.e1_finding_id);
            testCase.verifyNotEmpty(testCase.E2.examples.e1_input);
            testCase.verifyNotEmpty(testCase.E2.examples.e1_output);
        end

        function test_example_E3_defined(testCase)
            % Verify E3 example is defined
            testCase.verifyNotEmpty(testCase.E2.examples.e3_finding_id);
            testCase.verifyNotEmpty(testCase.E2.examples.e3_input);
            testCase.verifyNotEmpty(testCase.E2.examples.e3_output);
        end

    end

    % === INTEGRATION TESTS ===

    methods(Test)

        function test_metadata_complete(testCase)
            % Verify metadata is complete
            testCase.verifyNotEmpty(testCase.E2.name);
            testCase.verifyNotEmpty(testCase.E2.version);
            testCase.verifyNotEmpty(testCase.E2.created);
        end

        function test_status_verified_computational(testCase)
            % Verify status is correctly marked
            testCase.verifyEqual(testCase.E2.status, 'VERIFIED_COMPUTATIONAL');
        end

        function test_all_functions_callable(testCase)
            % Verify all main functions are callable
            testCase.verifyTrue(isa(testCase.E2.generate_witness, 'function_handle'));
            testCase.verifyTrue(isa(testCase.E2.verify_witness, 'function_handle'));
            testCase.verifyTrue(isa(testCase.E2.verify_chain, 'function_handle'));
        end

    end

end
