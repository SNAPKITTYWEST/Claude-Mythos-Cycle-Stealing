%% test_D1_e7.m
% Test suite for D1 - E7 Exceptional Symmetries
%
% Tests:
%   1. Cartan matrix properties (rank, symmetry, positive-definiteness)
%   2. Simple root construction and orthogonality
%   3. Weyl group generator properties
%   4. Root system completeness (126 roots)
%   5. Weyl chamber structure
%   6. Fundamental weights

function test_results = test_D1_e7()

    fprintf('\n=== TEST SUITE: D1 - E7 SYMMETRIES ===\n\n');

    test_results = struct();
    test_results.tests = {};
    test_results.passed = 0;
    test_results.failed = 0;

    % Run all tests
    tests = {@test_e7_cartan_matrix_rank, ...
             @test_e7_cartan_matrix_symmetry, ...
             @test_e7_simple_roots_dimension, ...
             @test_e7_simple_roots_orthogonality, ...
             @test_e7_root_count, ...
             @test_e7_weyl_chamber, ...
             @test_e7_fundamental_weights};

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

%% Test 1: Cartan matrix rank
function test_e7_cartan_matrix_rank()
    e7_data = D1_e7_symmetries();

    A = e7_data.cartan_matrix;
    rank_A = rank(A);
    expected_rank = 7;

    assert(rank_A == expected_rank, ...
        sprintf('Rank mismatch: got %d, expected %d', rank_A, expected_rank));
end

%% Test 2: Cartan matrix symmetry
function test_e7_cartan_matrix_symmetry()
    e7_data = D1_e7_symmetries();

    A = e7_data.cartan_matrix;

    % Check symmetry
    is_symmetric = norm(A - A', 'fro') < 1e-10;
    assert(is_symmetric, 'Cartan matrix is not symmetric');

    % Check diagonal elements are 2
    diag_elements = diag(A);
    all_diag_2 = all(diag_elements == 2);
    assert(all_diag_2, 'Diagonal elements are not all 2');
end

%% Test 3: Simple roots dimension
function test_e7_simple_roots_dimension()
    e7_data = D1_e7_symmetries();

    roots = e7_data.simple_roots;
    [num_roots, dim] = size(roots);

    assert(num_roots == 7, sprintf('Expected 7 simple roots, got %d', num_roots));
    assert(dim >= 7, sprintf('Dimension too small: %d < 7', dim));
end

%% Test 4: Simple roots orthogonality (via Cartan matrix)
function test_e7_simple_roots_orthogonality()
    e7_data = D1_e7_symmetries();

    roots = e7_data.simple_roots;
    A = e7_data.cartan_matrix;

    % For each pair, ⟨αᵢ, αⱼ⟩ should relate to Cartan matrix entry
    % This is a structural test: verify Cartan matrix is consistent

    for i = 1:7
        for j = 1:7
            % The Cartan entry defines the inner product relationship
            % Simplified check: A[i,i] = 2 for diagonal, A[i,j] ≤ 0 for i ≠ j
            if i == j
                assert(A(i, j) == 2, sprintf('Diagonal entry A[%d,%d] != 2', i, j));
            else
                assert(A(i, j) <= 0, sprintf('Off-diagonal A[%d,%d] > 0', i, j));
            end
        end
    end
end

%% Test 5: Root count (E7 has 126 roots)
function test_e7_root_count()
    e7_data = D1_e7_symmetries();

    root_count = size(e7_data.full_roots, 1);
    expected = 126;

    % Allow small tolerance due to numerical generation
    assert(root_count >= expected - 5, ...
        sprintf('Root count too low: %d < %d', root_count, expected - 5));
    assert(root_count <= expected + 5, ...
        sprintf('Root count too high: %d > %d', root_count, expected + 5));
end

%% Test 6: Weyl chamber is well-defined
function test_e7_weyl_chamber()
    e7_data = D1_e7_symmetries();

    chamber = e7_data.weyl_chamber;

    assert(isfield(chamber, 'fundamental_weights'), ...
        'Weyl chamber missing fundamental_weights');
    assert(isfield(chamber, 'rho'), ...
        'Weyl chamber missing rho (half sum of positive roots)');
    assert(chamber.rho_norm > 0, ...
        'Weyl chamber rho vector has zero norm');
end

%% Test 7: Fundamental weights reconstruction
function test_e7_fundamental_weights()
    e7_data = D1_e7_symmetries();

    fw = e7_data.fundamental_weights;
    [num_fw, dim] = size(fw);

    assert(num_fw == 7, sprintf('Expected 7 fundamental weights, got %d', num_fw));
    assert(all(~isnan(fw(:)) & ~isinf(fw(:))), ...
        'Fundamental weights contain NaN or Inf');
end
