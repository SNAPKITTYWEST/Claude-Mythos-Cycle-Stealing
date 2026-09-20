%% test_D2_i4.m
% Test suite for D2 - I4 Homogeneity Verification
%
% Tests:
%   1. I4 is degree-4 homogeneous: I4(r*z) = r^4 * I4(z)
%   2. Scaling factor verification at r = [0.5, 0.9, 1.0, 1.1, 2.0, 10.0]
%   3. Error bounds and numerical stability
%   4. Random vector test coverage
%   5. Edge cases (near-zero vectors, large vectors)

function test_results = test_D2_i4()

    fprintf('\n=== TEST SUITE: D2 - I4 HOMOGENEITY ===\n\n');

    test_results = struct();
    test_results.tests = {};
    test_results.passed = 0;
    test_results.failed = 0;

    tests = {@test_i4_homogeneity_basic, ...
             @test_i4_homogeneity_random, ...
             @test_i4_homogeneity_edge_cases, ...
             @test_i4_error_bounds, ...
             @test_i4_scaling_consistency, ...
             @test_i4_computational_stability};

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

%% Test 1: Basic homogeneity I4(r*z) = r^4 * I4(z)
function test_i4_homogeneity_basic()
    z = [1.0; 2.0; 3.0];

    i4_z = compute_i4_invariant(z);
    scaling_factors = [0.5, 1.0, 2.0, 5.0];

    tolerance = 1e-12;

    for r = scaling_factors
        z_scaled = r * z;
        i4_scaled = compute_i4_invariant(z_scaled);
        expected = (r^4) * i4_z;

        if abs(expected) > 1e-15
            rel_error = abs(i4_scaled - expected) / abs(expected);
        else
            rel_error = abs(i4_scaled - expected);
        end

        assert(rel_error < tolerance, ...
            sprintf('Homogeneity failed for r=%.2f: rel_error=%.2e', r, rel_error));
    end
end

%% Test 2: Random vector homogeneity tests
function test_i4_homogeneity_random()
    rng(123);
    num_tests = 20;
    scaling_factors = [0.5, 0.9, 1.0, 1.1, 2.0, 10.0];

    tolerance = 1e-10;

    for test_num = 1:num_tests
        z = randn(3, 1);
        i4_z = compute_i4_invariant(z);

        for r = scaling_factors
            z_scaled = r * z;
            i4_scaled = compute_i4_invariant(z_scaled);
            expected = (r^4) * i4_z;

            if abs(expected) > 1e-15
                rel_error = abs(i4_scaled - expected) / abs(expected);
            else
                rel_error = abs(i4_scaled - expected);
            end

            assert(rel_error < tolerance, ...
                sprintf('Random test %d, r=%.2f: rel_error=%.2e', test_num, r, rel_error));
        end
    end
end

%% Test 3: Edge cases
function test_i4_homogeneity_edge_cases()
    tolerance = 1e-10;
    scaling_factors = [0.1, 0.5, 2.0];

    % Case 1: Small vector
    z_small = [1e-6; 2e-6; 3e-6];
    i4_small = compute_i4_invariant(z_small);

    for r = scaling_factors
        z_scaled = r * z_small;
        i4_scaled = compute_i4_invariant(z_scaled);
        expected = (r^4) * i4_small;

        rel_error = abs(i4_scaled - expected) / (abs(expected) + 1e-20);
        assert(rel_error < tolerance, ...
            sprintf('Edge case (small): r=%.2f failed, rel_error=%.2e', r, rel_error));
    end

    % Case 2: Large vector
    z_large = [1e6; 2e6; 3e6];
    i4_large = compute_i4_invariant(z_large);

    for r = [0.1, 1.0]  % Avoid extreme scaling for large vectors
        z_scaled = r * z_large;
        i4_scaled = compute_i4_invariant(z_scaled);
        expected = (r^4) * i4_large;

        rel_error = abs(i4_scaled - expected) / (abs(expected) + 1e-20);
        assert(rel_error < tolerance, ...
            sprintf('Edge case (large): r=%.2f failed, rel_error=%.2e', r, rel_error));
    end
end

%% Test 4: Error bounds
function test_i4_error_bounds()
    results = D2_i4_homogeneity();

    % Verify that reported errors stay within bounds
    max_error = results.max_error;
    assert(max_error < 1e-8, ...
        sprintf('Maximum error too large: %.2e > 1e-8', max_error));

    % Median error should be even smaller
    assert(results.median_error < results.max_error, ...
        'Median error exceeds max error');
end

%% Test 5: Scaling consistency
function test_i4_scaling_consistency()
    z = [1.0; 2.0; 3.0];
    i4_z = compute_i4_invariant(z);

    % Composite scaling: I4(r1*(r2*z)) should equal I4((r1*r2)*z)
    r1 = 2.0;
    r2 = 3.0;

    z_scaled1 = r1 * (r2 * z);
    i4_scaled1 = compute_i4_invariant(z_scaled1);

    z_scaled2 = (r1 * r2) * z;
    i4_scaled2 = compute_i4_invariant(z_scaled2);

    tolerance = 1e-12;
    assert(abs(i4_scaled1 - i4_scaled2) < tolerance, ...
        'Composite scaling is inconsistent');
end

%% Test 6: Computational stability
function test_i4_computational_stability()
    % Test that repeated computation of I4 at same point gives same result

    z = [1.234; 5.678; 9.012];

    i4_results = [];
    for iter = 1:10
        i4_val = compute_i4_invariant(z);
        i4_results = [i4_results; i4_val];
    end

    % All results should be identical
    max_dev = max(i4_results) - min(i4_results);
    assert(max_dev < 1e-14, ...
        sprintf('Computational instability detected: max_dev=%.2e', max_dev));
end

%% Compute I4 invariant (helper function)
function i4 = compute_i4_invariant(z)
    % I4 is the 4-th power of the discriminant-like invariant
    % for binary quartic forms or genus-1 curves.

    z = z / (norm(z) + eps);

    d = length(z);

    if d >= 3
        % Primary term
        term1 = (z(1)*z(3) - z(2)^2)^2;

        if d >= 4
            % Cross terms if higher dimensional
            term2 = (z(1)*z(4) - z(2)*z(3))^2;
            term3 = (z(2)*z(4) - z(3)^2)^2;
            i4 = term1 + term2 + term3;
        else
            i4 = term1;
        end
    else
        % Lower dimension: pad with zeros
        z_pad = [z; zeros(3-d, 1)];
        term1 = (z_pad(1)*z_pad(3) - z_pad(2)^2)^2;
        i4 = term1;
    end
end
