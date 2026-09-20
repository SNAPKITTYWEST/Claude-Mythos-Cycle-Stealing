%% D2_I4_Homogeneity.m
% I4 Invariant Homogeneity Verification
%
% Status: CLAIMED
% Mechanism: Verify I4(r*z) = r^4 * I4(z) for scaling factors r
%
% I4 is a degree-4 homogeneous invariant used in:
%   - Invariant theory of binary forms
%   - Jordan normal form classification
%   - E7 representation analysis
%
% This module:
%   1. Constructs symbolic binary form z (genus 1 curve / elliptic curve invariant)
%   2. Computes I4(z) via classical invariant formulas
%   3. Tests I4(r*z) = r^4 * I4(z) for various r
%   4. Reports relative errors and scaling verification

function [test_results] = D2_i4_homogeneity()

    % Test parameters
    scaling_factors = [0.5, 0.9, 1.0, 1.1, 2.0, 10.0];
    test_cases = 20;  % number of random test vectors
    dimension = 3;    % test in C^3 (represents coordinates of z)

    % Storage for results
    results = struct();
    results.scaling_factors = scaling_factors;
    results.test_cases = test_cases;
    results.errors = [];
    results.max_error = 0;
    results.mean_error = 0;
    results.passed = true;
    tolerance = 1e-10;  % numerical tolerance for error

    fprintf('\n=== I4 HOMOGENEITY VERIFICATION ===\n');
    fprintf('Degree of homogeneity: 4\n');
    fprintf('Tolerance: %.2e\n\n', tolerance);

    % Generate random test vectors
    rng(42);  % reproducible randomness
    test_vectors = randn(test_cases, dimension);

    all_errors = [];

    for test_num = 1:test_cases
        z_base = test_vectors(test_num, :);

        % Compute baseline invariant
        i4_base = compute_i4_invariant(z_base);

        for r_idx = 1:length(scaling_factors)
            r = scaling_factors(r_idx);

            % Compute scaled vector
            z_scaled = r * z_base;

            % Compute invariant at scaled point
            i4_scaled = compute_i4_invariant(z_scaled);

            % Expected value: I4(r*z) = r^4 * I4(z)
            expected = (r^4) * i4_base;

            % Relative error
            if abs(expected) > eps
                relative_error = abs(i4_scaled - expected) / abs(expected);
            else
                % For very small values, use absolute error
                relative_error = abs(i4_scaled - expected);
            end

            all_errors = [all_errors; relative_error];

            % Record if error exceeds tolerance
            if relative_error > tolerance && abs(expected) > 1e-15
                fprintf('Test %2d, r=%6.2f: ALERT - RelError = %.2e\n', ...
                    test_num, r, relative_error);
                results.passed = false;
            end
        end
    end

    % Summary statistics
    results.errors = all_errors;
    results.max_error = max(all_errors);
    results.mean_error = mean(all_errors);
    results.median_error = median(all_errors);
    results.std_error = std(all_errors);

    fprintf('Test summary:\n');
    fprintf('  Total tests: %d\n', test_cases * length(scaling_factors));
    fprintf('  Max relative error: %.2e\n', results.max_error);
    fprintf('  Mean relative error: %.2e\n', results.mean_error);
    fprintf('  Median relative error: %.2e\n', results.median_error);
    fprintf('  Std dev error: %.2e\n', results.std_error);
    fprintf('  Status: %s\n', ternary(results.passed, 'PASS', 'ALERT'));

    % Per-factor analysis
    fprintf('\nPer-scaling-factor analysis:\n');
    fprintf('  r      | Mean Error    | Max Error     | Tests\n');
    fprintf('  -------|---------------|---------------|-------\n');

    for r_idx = 1:length(scaling_factors)
        r = scaling_factors(r_idx);
        idx_range = (r_idx-1)*test_cases + 1 : r_idx*test_cases;
        errors_for_r = all_errors(idx_range);

        fprintf('  %6.2f | %.2e | %.2e | %5d\n', ...
            r, mean(errors_for_r), max(errors_for_r), length(errors_for_r));
    end

    fprintf('\nHomogeneity property verification: %s\n\n', ...
        ternary(results.passed, 'VERIFIED', 'FAILED'));

    test_results = results;

end

%% Compute I4 invariant for binary form
function i4 = compute_i4_invariant(z)
    % I4 is the 4-th power of the discriminant-like invariant
    % for binary quartic forms or genus-1 curves.
    %
    % One standard construction: for a vector z ∈ C³ representing
    % coefficients of a homogeneous polynomial, compute a degree-4 invariant.
    %
    % Generic formula: I4 involves determinants and symmetric products.
    % For simplicity, we use a classical invariant from algebraic geometry.

    % Normalize z to avoid numerical issues
    z = z / (norm(z) + eps);

    % Standard construction for degree-4 homogeneous invariant:
    % Compute via the Gram determinant (a degree-4 form)

    d = length(z);

    % For d=3 case (typical):
    % I4(z) = (z1*z3 - z2^2)^2 + permutations
    % This is related to the discriminant

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
        % Lower dimension: pad with zeros or use power form
        z_pad = [z, zeros(1, 3-d)];
        term1 = (z_pad(1)*z_pad(3) - z_pad(2)^2)^2;
        i4 = term1;
    end

    % Verify homogeneity by power counting
    % All terms should have total degree 4 in the entries
end

%% Test helper: ternary operator
function result = ternary(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end
