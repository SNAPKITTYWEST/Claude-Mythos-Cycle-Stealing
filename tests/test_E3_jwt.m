% test_E3_jwt.m - Unit tests for E3 JWT Witness Evolution
% Status: VERIFIED_COMPUTATIONAL
% Tests finite state evolution, transient analysis, limit cycles

classdef test_E3_jwt < matlab.unittest.TestCase

    properties
        E3
    end

    methods(TestMethodSetup)
        function setup(testCase)
            testCase.E3 = E3_jwt_evolution();
        end
    end

    % === STATE SPACE DEFINITION TESTS ===

    methods(Test)

        function test_alphabet_defined(testCase)
            % Verify alphabet is {-1, 0, +1}
            expected = [-1, 0, 1];
            testCase.verifyEqual(testCase.E3.alphabet, expected);
        end

        function test_tuple_size_three(testCase)
            % Verify witness states are 3-tuples
            testCase.verifyEqual(testCase.E3.tuple_size, 3);
        end

        function test_state_space_size_27(testCase)
            % Verify 3^3 = 27 possible states
            testCase.verifyEqual(testCase.E3.state_space_size, 27);
        end

        function test_all_states_generated(testCase)
            % Verify all 27 states are generated
            testCase.verifyEqual(size(testCase.E3.all_states, 1), 27);
            testCase.verifyEqual(size(testCase.E3.all_states, 2), 3);
        end

        function test_all_states_valid(testCase)
            % Verify all generated states have valid entries
            for i = 1 : size(testCase.E3.all_states, 1)
                state = testCase.E3.all_states(i, :);
                testCase.verifyTrue(all(ismember(state, [-1, 0, 1])));
                testCase.verifyEqual(length(state), 3);
            end
        end

    end

    % === STATE TRANSITION FUNCTION Q TESTS ===

    methods(Test)

        function test_Q_callable(testCase)
            % Verify Q transition function is callable
            testCase.verifyTrue(isa(testCase.E3.Q, 'function_handle'));
        end

        function test_Q_identity_elements(testCase)
            % Q(a, a) = a for all a ∈ Σ
            for a = testCase.E3.alphabet
                result = testCase.E3.Q(a, a);
                testCase.verifyEqual(result, a);
            end
        end

        function test_Q_output_in_alphabet(testCase)
            % Property: Q(a, b) ∈ Σ for all a, b ∈ Σ
            for a = testCase.E3.alphabet
                for b = testCase.E3.alphabet
                    result = testCase.E3.Q(a, b);
                    testCase.verifyTrue(ismember(result, testCase.E3.alphabet));
                end
            end
        end

        function test_Q_deterministic(testCase)
            % Property: Q is deterministic
            for a = testCase.E3.alphabet
                for b = testCase.E3.alphabet
                    result1 = testCase.E3.Q(a, b);
                    result2 = testCase.E3.Q(a, b);
                    testCase.verifyEqual(result1, result2);
                end
            end
        end

    end

    % === EVOLUTION RULE TESTS ===

    methods(Test)

        function test_evolve_state_callable(testCase)
            % Verify evolution function is callable
            testCase.verifyTrue(isa(testCase.E3.evolve_state, 'function_handle'));
        end

        function test_evolve_state_preserves_structure(testCase)
            % Evolution preserves 3-tuple structure
            w_init = [-1, 0, 1];
            w_next = testCase.E3.evolve_state(w_init);

            testCase.verifyEqual(length(w_next), 3);
            testCase.verifyTrue(all(ismember(w_next, testCase.E3.alphabet)));
        end

        function test_evolve_trajectory_callable(testCase)
            % Verify trajectory evolution is callable
            testCase.verifyTrue(isa(testCase.E3.evolve_trajectory, 'function_handle'));
        end

        function test_evolve_trajectory_produces_sequence(testCase)
            % Generate trajectory for 10 steps
            w_init = [1, 0, -1];
            trajectory = testCase.E3.evolve_trajectory(w_init, 10, testCase.E3.evolve_state);

            % Should have 11 rows (steps 0 through 10)
            testCase.verifyEqual(size(trajectory, 1), 11);
            testCase.verifyEqual(size(trajectory, 2), 3);
        end

        function test_trajectory_first_state_is_init(testCase)
            % First state in trajectory is initial state
            w_init = [1, 0, -1];
            trajectory = testCase.E3.evolve_trajectory(w_init, 5, testCase.E3.evolve_state);

            testCase.verifyEqual(trajectory(1, :), w_init);
        end

    end

    % === TRANSIENT & LIMIT CYCLE ANALYSIS TESTS ===

    methods(Test)

        function test_transient_analysis_callable(testCase)
            % Verify transient analysis is callable
            testCase.verifyTrue(isa(testCase.E3.transient_analysis, 'function_handle'));
        end

        function test_transient_analysis_produces_results(testCase)
            % Run transient analysis
            w_init = [1, 0, 1];
            [trans_len, period] = testCase.E3.transient_analysis(w_init, 100);

            testCase.verifyTrue(isnumeric(trans_len));
            testCase.verifyTrue(isnumeric(period));
        end

        function test_transient_nonnegative(testCase)
            % Transient length is non-negative
            w_init = [1, 0, 1];
            [trans_len, ~] = testCase.E3.transient_analysis(w_init, 100);

            testCase.verifyGreaterThanOrEqual(trans_len, 0);
        end

        function test_period_positive(testCase)
            % Period is positive
            w_init = [1, 0, 1];
            [~, period] = testCase.E3.transient_analysis(w_init, 100);

            testCase.verifyGreaterThan(period, 0);
        end

        function test_find_limit_cycle_callable(testCase)
            % Verify limit cycle finding is callable
            testCase.verifyTrue(isa(testCase.E3.find_limit_cycle, 'function_handle'));
        end

        function test_find_absorbing_states_callable(testCase)
            % Verify absorbing state finding is callable
            testCase.verifyTrue(isa(testCase.E3.find_absorbing_states, 'function_handle'));
        end

    end

    % === MAXIMUM TRANSIENT BOUND TESTS ===

    methods(Test)

        function test_compute_max_transient_callable(testCase)
            % Verify T computation is callable
            testCase.verifyTrue(isa(testCase.E3.compute_max_transient, 'function_handle'));
        end

        function test_max_transient_value(testCase)
            % Compute maximum transient length over all states
            % Should be <= 36 (derived, not hardcoded)
            max_T = testCase.E3.compute_max_transient();

            testCase.verifyLessThanOrEqual(max_T, 36);
            testCase.verifyGreaterThanOrEqual(max_T, 0);
        end

        function test_verify_transient_bound_callable(testCase)
            % Verify transient bound verification is callable
            testCase.verifyTrue(isa(testCase.E3.verify_transient_bound, 'function_handle'));
        end

        function test_verify_all_transients_bounded(testCase)
            % All transient lengths should be bounded by 36
            is_bounded = testCase.E3.verify_transient_bound();
            testCase.verifyTrue(is_bounded);
        end

    end

    % === STATE GRAPH COMPUTATION TESTS ===

    methods(Test)

        function test_build_state_graph_callable(testCase)
            % Verify graph building is callable
            testCase.verifyTrue(isa(testCase.E3.build_state_graph, 'function_handle'));
        end

        function test_compute_graph_metrics_callable(testCase)
            % Verify graph metrics computation is callable
            testCase.verifyTrue(isa(testCase.E3.compute_graph_metrics, 'function_handle'));
        end

        function test_graph_structure(testCase)
            % Build and verify graph structure
            graph = testCase.E3.build_state_graph();

            testCase.verifyTrue(issparse(graph) || ismatrix(graph));
            testCase.verifyEqual(size(graph, 1), 27);
            testCase.verifyEqual(size(graph, 2), 27);
        end

    end

    % === ALGEBRAIC STRUCTURE TESTS ===

    methods(Test)

        function test_operation_Q_table_callable(testCase)
            % Verify Q table generation is callable
            testCase.verifyTrue(isa(testCase.E3.operation_Q_table, 'function_handle'));
        end

        function test_Q_table_3x3(testCase)
            % Operation Q table should be 3x3
            Q_table = testCase.E3.operation_Q_table();

            testCase.verifyEqual(size(Q_table, 1), 3);
            testCase.verifyEqual(size(Q_table, 2), 3);
        end

        function test_Q_table_valid_entries(testCase)
            % All Q_table entries are in alphabet
            Q_table = testCase.E3.operation_Q_table();

            for i = 1 : 3
                for j = 1 : 3
                    val = Q_table(i, j);
                    testCase.verifyTrue(ismember(val, testCase.E3.alphabet));
                end
            end
        end

        function test_check_associativity_callable(testCase)
            % Verify associativity check is callable
            testCase.verifyTrue(isa(testCase.E3.check_Q_associativity, 'function_handle'));
        end

        function test_check_commutativity_callable(testCase)
            % Verify commutativity check is callable
            testCase.verifyTrue(isa(testCase.E3.check_Q_commutativity, 'function_handle'));
        end

    end

    % === VERIFICATION INVARIANT TESTS ===

    methods(Test)

        function test_invariant_I1_finite_states(testCase)
            % I1: All states have correct dimension and alphabet membership
            for i = 1 : size(testCase.E3.all_states, 1)
                state = testCase.E3.all_states(i, :);
                testCase.verifyEqual(length(state), 3);
                testCase.verifyTrue(all(ismember(state, [-1, 0, 1])));
            end
        end

        function test_invariant_I2_deterministic(testCase)
            % I2: Evolution is deterministic
            is_determ = testCase.E3.verify_determinism();
            testCase.verifyTrue(is_determ);
        end

        function test_invariant_I3_bounded(testCase)
            % I3: Transient length T <= 36
            is_bounded = testCase.E3.verify_transient_bound();
            testCase.verifyTrue(is_bounded);
        end

        function test_invariant_I4_convergence(testCase)
            % I4: All trajectories converge
            converge = testCase.E3.verify_convergence(500);
            testCase.verifyTrue(converge);
        end

    end

    % === WITNESS SEMANTICS TESTS ===

    methods(Test)

        function test_interpret_state_callable(testCase)
            % Verify state interpretation is callable
            testCase.verifyTrue(isa(testCase.E3.interpret_state, 'function_handle'));
        end

        function test_interpret_state_produces_string(testCase)
            % State interpretation produces interpretable output
            w = [1, 0, -1];
            interpretation = testCase.E3.interpret_state(w);

            testCase.verifyTrue(ischar(interpretation) || isstring(interpretation));
        end

    end

    % === FIXED POINT ANALYSIS TESTS ===

    methods(Test)

        function test_fixed_points_callable(testCase)
            % Verify fixed point finding is callable
            testCase.verifyTrue(isa(testCase.E3.fixed_points, 'function_handle'));
        end

        function test_periodic_orbits_callable(testCase)
            % Verify periodic orbit finding is callable
            testCase.verifyTrue(isa(testCase.E3.periodic_orbits, 'function_handle'));
        end

        function test_fixed_points_exist(testCase)
            % At least one fixed point should exist
            fps = testCase.E3.fixed_points();

            testCase.verifyGreaterThan(size(fps, 1), 0);
        end

        function test_fixed_points_satisfy_property(testCase)
            % All fixed points satisfy w = evolve(w)
            fps = testCase.E3.fixed_points();

            for i = 1 : size(fps, 1)
                w = fps(i, :);
                w_next = testCase.E3.evolve_state(w);
                testCase.verifyEqual(w, w_next);
            end
        end

    end

    % === CONFIGURATION TESTS ===

    methods(Test)

        function test_config_max_simulation_steps(testCase)
            % Verify max simulation steps configured
            testCase.verifyGreaterThan(testCase.E3.config.max_simulation_steps, 0);
        end

        function test_config_convergence_window(testCase)
            % Verify convergence detection window
            testCase.verifyGreaterThan(testCase.E3.config.convergence_detection_window, 0);
        end

        function test_config_theoretical_bound(testCase)
            % Verify theoretical bound is set to 36
            testCase.verifyEqual(testCase.E3.config.theoretical_bound_T, 36);
        end

        function test_config_exploration_complete(testCase)
            % Verify state space exploration flag
            testCase.verifyTrue(testCase.E3.config.state_space_exploration_complete);
        end

    end

    % === METADATA & STATUS TESTS ===

    methods(Test)

        function test_metadata_name(testCase)
            % Verify framework name
            testCase.verifyNotEmpty(testCase.E3.name);
        end

        function test_metadata_version(testCase)
            % Verify version information
            testCase.verifyNotEmpty(testCase.E3.version);
        end

        function test_metadata_created(testCase)
            % Verify creation timestamp
            testCase.verifyNotEmpty(testCase.E3.created);
        end

        function test_status_verified_computational(testCase)
            % Verify status is correctly marked
            testCase.verifyEqual(testCase.E3.status, 'VERIFIED_COMPUTATIONAL');
        end

    end

    % === INTEGRATION TESTS ===

    methods(Test)

        function test_all_functions_present(testCase)
            % Verify all major functions are defined
            testCase.verifyTrue(isa(testCase.E3.evolve_state, 'function_handle'));
            testCase.verifyTrue(isa(testCase.E3.evolve_trajectory, 'function_handle'));
            testCase.verifyTrue(isa(testCase.E3.transient_analysis, 'function_handle'));
            testCase.verifyTrue(isa(testCase.E3.compute_max_transient, 'function_handle'));
        end

        function test_example_trajectories_work(testCase)
            % Run example trajectories
            w_init1 = [1, 1, 1];
            traj1 = testCase.E3.evolve_trajectory(w_init1, 20, testCase.E3.evolve_state);

            testCase.verifyEqual(size(traj1, 1), 21);

            w_init2 = [-1, 0, 1];
            traj2 = testCase.E3.evolve_trajectory(w_init2, 20, testCase.E3.evolve_state);

            testCase.verifyEqual(size(traj2, 1), 21);
        end

    end

end
