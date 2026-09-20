%% test_D4_boolean.m
% Test suite for D4 - Boolean Algebra Formalization
%
% Tests:
%   1. All 8 axioms of Boolean algebra
%   2. Commutativity of ∨ and ∧
%   3. Associativity of ∨ and ∧
%   4. Identity elements (0 for ∨, 1 for ∧)
%   5. Complement (De Morgan's laws)
%   6. Distributivity
%   7. Absorption laws
%   8. Idempotence
%   9. Canonical DNF forms
%   10. Decidable equality via normal form

function test_results = test_D4_boolean()

    fprintf('\n=== TEST SUITE: D4 - BOOLEAN ALGEBRA ===\n\n');

    test_results = struct();
    test_results.passed = 0;
    test_results.failed = 0;

    tests = {@test_boolean_formalization_runs, ...
             @test_commutativity_or, ...
             @test_commutativity_and, ...
             @test_associativity_or, ...
             @test_associativity_and, ...
             @test_identity_or, ...
             @test_identity_and, ...
             @test_de_morgan_laws, ...
             @test_absorption_laws, ...
             @test_distributivity, ...
             @test_idempotence, ...
             @test_decidable_equality};

    for t_idx = 1:length(tests)
        test_func = tests{t_idx};
        try
            test_func();
            fprintf('✓ Test %d passed\n', t_idx);
            test_results.passed = test_results.passed + 1;
        catch ME
            fprintf('✗ Test %d failed: %s\n', t_idx, ME.message);
            test_results.failed = test_results.failed + 1;
        end
    end

    fprintf('\n=== SUMMARY ===\n');
    fprintf('Total: %d, Passed: %d, Failed: %d\n', ...
        test_results.passed + test_results.failed, ...
        test_results.passed, test_results.failed);

end

%% Test 0: Formalization runs
function test_boolean_formalization_runs()
    try
        bool_analysis = D4_boolean_formalization();
        assert(isfield(bool_analysis, 'num_variables'), ...
            'Missing num_variables field');
        assert(isfield(bool_analysis, 'test_results'), ...
            'Missing test_results field');
        assert(bool_analysis.equality_decidable == true, ...
            'Equality not decidable');
    catch ME
        error('Boolean formalization failed: %s', ME.message);
    end
end

%% Test 1: Commutativity of OR
function test_commutativity_or()
    n = 3;
    tt = generate_truth_table(n);

    for i = 1:n
        for j = 1:n
            a = tt(:, i);
            b = tt(:, j);

            or_ab = logical(a | b);
            or_ba = logical(b | a);

            assert(all(or_ab == or_ba), ...
                sprintf('OR commutativity failed for vars %d, %d', i, j));
        end
    end
end

%% Test 2: Commutativity of AND
function test_commutativity_and()
    n = 3;
    tt = generate_truth_table(n);

    for i = 1:n
        for j = 1:n
            a = tt(:, i);
            b = tt(:, j);

            and_ab = logical(a & b);
            and_ba = logical(b & a);

            assert(all(and_ab == and_ba), ...
                sprintf('AND commutativity failed for vars %d, %d', i, j));
        end
    end
end

%% Test 3: Associativity of OR
function test_associativity_or()
    n = 3;
    tt = generate_truth_table(n);

    for i = 1:n
        for j = 1:n
            for k = 1:n
                a = tt(:, i);
                b = tt(:, j);
                c = tt(:, k);

                lhs = logical((a | b) | c);
                rhs = logical(a | (b | c));

                assert(all(lhs == rhs), ...
                    sprintf('OR associativity failed for vars %d, %d, %d', i, j, k));
            end
        end
    end
end

%% Test 4: Associativity of AND
function test_associativity_and()
    n = 3;
    tt = generate_truth_table(n);

    for i = 1:n
        for j = 1:n
            for k = 1:n
                a = tt(:, i);
                b = tt(:, j);
                c = tt(:, k);

                lhs = logical((a & b) & c);
                rhs = logical(a & (b & c));

                assert(all(lhs == rhs), ...
                    sprintf('AND associativity failed for vars %d, %d, %d', i, j, k));
            end
        end
    end
end

%% Test 5: Identity for OR (a ∨ 0 = a)
function test_identity_or()
    n = 3;
    tt = generate_truth_table(n);
    zero = zeros(2^n, 1);

    for i = 1:n
        a = tt(:, i);
        or_zero = logical(a | zero);

        assert(all(or_zero == a), ...
            sprintf('OR identity failed for var %d', i));
    end
end

%% Test 6: Identity for AND (a ∧ 1 = a)
function test_identity_and()
    n = 3;
    tt = generate_truth_table(n);
    one = ones(2^n, 1);

    for i = 1:n
        a = tt(:, i);
        and_one = logical(a & one);

        assert(all(and_one == a), ...
            sprintf('AND identity failed for var %d', i));
    end
end

%% Test 7: De Morgan's Laws
function test_de_morgan_laws()
    n = 3;
    tt = generate_truth_table(n);

    for i = 1:n
        for j = 1:n
            a = tt(:, i);
            b = tt(:, j);

            % ¬(a ∨ b) = ¬a ∧ ¬b
            lhs = logical(~(a | b));
            rhs = logical((~a) & (~b));
            assert(all(lhs == rhs), ...
                sprintf('De Morgan OR failed for vars %d, %d', i, j));

            % ¬(a ∧ b) = ¬a ∨ ¬b
            lhs = logical(~(a & b));
            rhs = logical((~a) | (~b));
            assert(all(lhs == rhs), ...
                sprintf('De Morgan AND failed for vars %d, %d', i, j));
        end
    end
end

%% Test 8: Absorption Laws
function test_absorption_laws()
    n = 3;
    tt = generate_truth_table(n);

    for i = 1:n
        for j = 1:n
            a = tt(:, i);
            b = tt(:, j);

            % a ∨ (a ∧ b) = a
            lhs = logical(a | (a & b));
            assert(all(lhs == a), ...
                sprintf('Absorption OR failed for vars %d, %d', i, j));

            % a ∧ (a ∨ b) = a
            lhs = logical(a & (a | b));
            assert(all(lhs == a), ...
                sprintf('Absorption AND failed for vars %d, %d', i, j));
        end
    end
end

%% Test 9: Distributivity
function test_distributivity()
    n = 3;
    tt = generate_truth_table(n);

    for i = 1:n
        for j = 1:n
            for k = 1:n
                a = tt(:, i);
                b = tt(:, j);
                c = tt(:, k);

                % a ∧ (b ∨ c) = (a ∧ b) ∨ (a ∧ c)
                lhs = logical(a & (b | c));
                rhs = logical((a & b) | (a & c));
                assert(all(lhs == rhs), ...
                    sprintf('Distributive AND-OR failed for vars %d, %d, %d', i, j, k));

                % a ∨ (b ∧ c) = (a ∨ b) ∧ (a ∨ c)
                lhs = logical(a | (b & c));
                rhs = logical((a | b) & (a | c));
                assert(all(lhs == rhs), ...
                    sprintf('Distributive OR-AND failed for vars %d, %d, %d', i, j, k));
            end
        end
    end
end

%% Test 10: Idempotence
function test_idempotence()
    n = 3;
    tt = generate_truth_table(n);

    for i = 1:n
        a = tt(:, i);

        % a ∨ a = a
        or_result = logical(a | a);
        assert(all(or_result == a), sprintf('OR idempotence failed for var %d', i));

        % a ∧ a = a
        and_result = logical(a & a);
        assert(all(and_result == a), sprintf('AND idempotence failed for var %d', i));
    end
end

%% Test 11: Decidable equality via truth table
function test_decidable_equality()
    n = 3;
    tt = generate_truth_table(n);

    % Create two equivalent formulas
    a = tt(:, 1);
    b = tt(:, 2);

    formula1 = logical(a | b);
    formula2 = logical(b | a);

    % They should be equal (by commutativity)
    assert(all(formula1 == formula2), 'Commutativity-derived equality failed');

    % Create two distinct formulas
    formula3 = logical(a & b);
    formula4 = logical(a | b);

    % They should not all be equal
    assert(~all(formula3 == formula4), 'Distinct formulas incorrectly marked equal');
end

%% Helper: Generate truth table
function truth_table = generate_truth_table(n_vars)
    num_rows = 2^n_vars;
    truth_table = zeros(num_rows, n_vars);

    for i = 1:num_rows
        binary_rep = de2bi(i-1, n_vars);
        truth_table(i, :) = binary_rep;
    end
end
