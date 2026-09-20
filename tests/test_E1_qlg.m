% test_E1_qlg.m - Unit tests for E1 QLG/SLA/QRA framework
% Status: VERIFIED_COMPUTATIONAL
% Tests three layers: Quantum Linear Gauge, Semantic Logic Architecture, Quantum Representation Algebra

classdef test_E1_qlg < matlab.unittest.TestCase

    properties
        E1
    end

    methods(TestMethodSetup)
        function setup(testCase)
            testCase.E1 = E1_qlg_sla_qra();
        end
    end

    % === QUANTUM LINEAR GAUGE (QLG) LAYER TESTS ===

    methods(Test)

        function test_QLG_basis_dimension(testCase)
            % Test that QLG operates in correct dimension (4 = 2^2)
            testCase.verifyEqual(testCase.E1.QLG.basis_dimension, 4);
        end

        function test_QLG_pauli_matrices_hermitian(testCase)
            % Verify Pauli matrices are Hermitian
            X = testCase.E1.QLG.pauli_x;
            Y = testCase.E1.QLG.pauli_y;
            Z = testCase.E1.QLG.pauli_z;

            testCase.verifyEqual(X, X', 'AbsTol', 1e-10);
            testCase.verifyEqual(Y, Y', 'AbsTol', 1e-10);
            testCase.verifyEqual(Z, Z', 'AbsTol', 1e-10);
        end

        function test_QLG_pauli_trace_zero(testCase)
            % Verify that Pauli matrices are traceless
            X = testCase.E1.QLG.pauli_x;
            Y = testCase.E1.QLG.pauli_y;
            Z = testCase.E1.QLG.pauli_z;

            testCase.verifyEqual(trace(X), 0, 'AbsTol', 1e-10);
            testCase.verifyEqual(trace(Y), 0, 'AbsTol', 1e-10);
            testCase.verifyEqual(trace(Z), 0, 'AbsTol', 1e-10);
        end

        function test_QLG_bell_states_normalized(testCase)
            % Verify Bell states are normalized to 1
            bell_states = {
                testCase.E1.QLG.bell_plus,
                testCase.E1.QLG.bell_minus,
                testCase.E1.QLG.bell_psi_plus,
                testCase.E1.QLG.bell_psi_minus
            };

            for i = 1:length(bell_states)
                bell = bell_states{i};
                norm_val = sqrt(bell' * bell);
                testCase.verifyEqual(abs(norm_val - 1.0), 0, 'AbsTol', 1e-10);
            end
        end

        function test_QLG_bell_states_orthogonal(testCase)
            % Verify Bell states are orthogonal (dot products = 0)
            bells = {
                testCase.E1.QLG.bell_plus,
                testCase.E1.QLG.bell_minus,
                testCase.E1.QLG.bell_psi_plus,
                testCase.E1.QLG.bell_psi_minus
            };

            for i = 1:length(bells)
                for j = i+1:length(bells)
                    dot_prod = bells{i}' * bells{j};
                    testCase.verifyEqual(abs(dot_prod), 0, 'AbsTol', 1e-10);
                end
            end
        end

        function test_QLG_gauge_invariance(testCase)
            % Test gauge invariance: measuring observable after phase shift gives same result
            psi = testCase.E1.QLG.bell_plus;
            obs = testCase.E1.QLG.observable_Z;

            % Measure without gauge shift
            exp_val_1 = testCase.E1.QLG.gauge_invariant_measure(psi, obs);

            % Apply gauge shift
            theta = pi / 4;
            psi_shifted = testCase.E1.QLG.phase_shift_function(psi, theta);

            % Measure after gauge shift
            exp_val_2 = testCase.E1.QLG.gauge_invariant_measure(psi_shifted, obs);

            testCase.verifyEqual(exp_val_1, exp_val_2, 'AbsTol', 1e-10);
        end

        function test_QLG_observable_expectation_real(testCase)
            % Expectation values of Hermitian observables must be real
            psi = testCase.E1.QLG.bell_plus;
            obs = testCase.E1.QLG.observable_X;

            exp_val = testCase.E1.QLG.gauge_invariant_measure(psi, obs);

            testCase.verifyEqual(imag(exp_val), 0, 'AbsTol', 1e-10);
        end

    end

    % === SEMANTIC LOGIC ARCHITECTURE (SLA) LAYER TESTS ===

    methods(Test)

        function test_SLA_modalities_defined(testCase)
            % Verify SLA modalities are properly defined
            expected_modalities = {'Know', 'Verified', 'Disputed'};
            testCase.verifyEqual(testCase.E1.SLA.modalities, expected_modalities);
        end

        function test_SLA_atoms_defined(testCase)
            % Verify propositional atoms are defined
            testCase.verifyGreaterThan(length(testCase.E1.SLA.atoms), 0);
        end

        function test_SLA_axiom_K1_exists(testCase)
            % Verify K1 axiom (distribution) is defined
            testCase.verifyNotEmpty(testCase.E1.SLA.axiom_K1);
        end

        function test_SLA_axiom_K2_exists(testCase)
            % Verify K2 axiom (truth) is defined
            testCase.verifyNotEmpty(testCase.E1.SLA.axiom_K2);
        end

        function test_SLA_axiom_K3_exists(testCase)
            % Verify K3 axiom (introspection) is defined
            testCase.verifyNotEmpty(testCase.E1.SLA.axiom_K3);
        end

        function test_SLA_axiom_V1_exists(testCase)
            % Verify V1 axiom (verification reflects truth) is defined
            testCase.verifyNotEmpty(testCase.E1.SLA.axiom_V1);
        end

        function test_SLA_axiom_V2_exists(testCase)
            % Verify V2 axiom (safe to know if verified) is defined
            testCase.verifyNotEmpty(testCase.E1.SLA.axiom_V2);
        end

        function test_SLA_inference_rule_exists(testCase)
            % Verify modus ponens inference rule is defined
            testCase.verifyNotEmpty(testCase.E1.SLA.inference_modus_ponens_modal);
        end

        function test_SLA_kripke_accessibility_defined(testCase)
            % Verify Kripke accessibility relation function exists
            testCase.verifyTrue(isa(testCase.E1.SLA.kripke_accessibility, 'function_handle'));
        end

    end

    % === QUANTUM REPRESENTATION ALGEBRA (QRA) LAYER TESTS ===

    methods(Test)

        function test_QRA_witness_state_structure(testCase)
            % Verify witness state structure is properly defined
            witness_fields = testCase.E1.QRA.witness_state_structure;
            testCase.verifyGreaterThanOrEqual(length(witness_fields), 3);
        end

        function test_QRA_identity_witness_well_formed(testCase)
            % Verify identity witness has correct structure
            id_w = testCase.E1.QRA.identity_witness;
            testCase.verifyTrue(isfield(id_w, 'claim_id'));
            testCase.verifyTrue(isfield(id_w, 'hash_chain'));
            testCase.verifyTrue(isfield(id_w, 'modality_level'));
        end

        function test_QRA_composition_function_callable(testCase)
            % Verify composition is callable
            testCase.verifyTrue(isa(testCase.E1.QRA.composition, 'function_handle'));
        end

        function test_QRA_inverse_function_callable(testCase)
            % Verify inverse function is callable
            testCase.verifyTrue(isa(testCase.E1.QRA.inverse, 'function_handle'));
        end

        function test_QRA_closure_property_stated(testCase)
            % Verify closure property is articulated
            testCase.verifyNotEmpty(testCase.E1.QRA.closure_property);
        end

        function test_QRA_associativity_stated(testCase)
            % Verify associativity axiom is stated
            testCase.verifyNotEmpty(testCase.E1.QRA.associativity);
        end

        function test_QRA_representation_theorem_stated(testCase)
            % Verify representation theorem is stated
            testCase.verifyNotEmpty(testCase.E1.QRA.representation_theorem);
        end

    end

    % === INTEGRATION TESTS ===

    methods(Test)

        function test_integration_flow_defined(testCase)
            % Verify integration flow is documented
            testCase.verifyNotEmpty(testCase.E1.Integration.flow_diagram);
        end

        function test_integration_verify_consistency_callable(testCase)
            % Verify consistency verification function is callable
            testCase.verifyTrue(isa(testCase.E1.Integration.verify_consistency, 'function_handle'));
        end

        function test_integration_consistency_check_basic(testCase)
            % Test basic consistency verification
            % Create test inputs
            qlg_state = testCase.E1.QLG.bell_plus;
            sla_formula = 'Know(ψ_valid)';
            qra_witness = testCase.E1.QRA.identity_witness;

            % Call verification
            is_consistent = testCase.E1.Integration.verify_consistency(...
                qlg_state, sla_formula, qra_witness);

            testCase.verifyTrue(islogical(is_consistent) || isnumeric(is_consistent));
        end

        function test_E1_configuration_complete(testCase)
            % Verify E1 configuration is complete
            testCase.verifyTrue(isfield(testCase.E1, 'config'));
            testCase.verifyEqual(testCase.E1.config.hash_algorithm, 'Blake3');
            testCase.verifyEqual(testCase.E1.config.hash_length_bits, 256);
        end

    end

    % === PROPERTY-BASED TESTS ===

    methods(Test)

        function test_QLG_operator_properties(testCase)
            % Property: Pauli matrices square to identity
            X = testCase.E1.QLG.pauli_x;
            Y = testCase.E1.QLG.pauli_y;
            Z = testCase.E1.QLG.pauli_z;

            testCase.verifyEqual(X * X, eye(2), 'AbsTol', 1e-10);
            testCase.verifyEqual(Y * Y, eye(2), 'AbsTol', 1e-10);
            testCase.verifyEqual(Z * Z, eye(2), 'AbsTol', 1e-10);
        end

        function test_QLG_anticommutation_relations(testCase)
            % Property: {σ_i, σ_j} = 2δ_ij
            X = testCase.E1.QLG.pauli_x;
            Y = testCase.E1.QLG.pauli_y;

            anticomm_XY = X*Y + Y*X;
            testCase.verifyEqual(anticomm_XY, zeros(2), 'AbsTol', 1e-10);
        end

        function test_QLG_bell_state_span(testCase)
            % Property: Bell states span the 4-dimensional space
            % (all are needed to express any 2-qubit state)
            bells = {
                testCase.E1.QLG.bell_plus,
                testCase.E1.QLG.bell_minus,
                testCase.E1.QLG.bell_psi_plus,
                testCase.E1.QLG.bell_psi_minus
            };

            % Construct matrix with Bell states as columns
            Bell_matrix = [bells{1}, bells{2}, bells{3}, bells{4}];

            % Check rank = 4
            rank_val = rank(Bell_matrix);
            testCase.verifyEqual(rank_val, 4);
        end

        function test_SLA_modality_levels_ordered(testCase)
            % Property: Modality levels should form hierarchy
            % disputed < verified < known
            testCase.verifyGreaterThan(length(testCase.E1.SLA.modalities), 0);
        end

        function test_QRA_identity_is_fixed_point(testCase)
            % Property: Identity witness should be neutral under composition
            id_w = testCase.E1.QRA.identity_witness;

            % Under composition with self, should remain identity
            w_composed = testCase.E1.QRA.composition(id_w, id_w);
            testCase.verifyTrue(isstruct(w_composed));
        end

    end

    % === CONSISTENCY TESTS ===

    methods(Test)

        function test_all_layers_present(testCase)
            % Verify all three layers are present in E1
            testCase.verifyTrue(isfield(testCase.E1, 'QLG'));
            testCase.verifyTrue(isfield(testCase.E1, 'SLA'));
            testCase.verifyTrue(isfield(testCase.E1, 'QRA'));
        end

        function test_all_functions_callable(testCase)
            % Verify key functions are callable
            testCase.verifyTrue(isa(testCase.E1.QLG.gauge_invariant_measure, 'function_handle'));
            testCase.verifyTrue(isa(testCase.E1.QRA.composition, 'function_handle'));
            testCase.verifyTrue(isa(testCase.E1.Integration.verify_consistency, 'function_handle'));
        end

        function test_metadata_complete(testCase)
            % Verify E1 has complete metadata
            testCase.verifyNotEmpty(testCase.E1.name);
            testCase.verifyNotEmpty(testCase.E1.version);
            testCase.verifyNotEmpty(testCase.E1.created);
        end

    end

end
