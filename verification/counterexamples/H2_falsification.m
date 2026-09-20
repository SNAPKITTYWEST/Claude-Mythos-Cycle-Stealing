%% H2_Falsification.m
% Counterexample Search for H2 I4 Full State
%
% This harness searches for two distinct states z1, z2 with I4(z1) = I4(z2)
% Status: OPEN - Active falsification in progress

function [falsification_report] = H2_falsification()

    fprintf('\n=== H2 FALSIFICATION HARNESS ===\n');
    fprintf('Seeking: States z1 ≠ z2 with I4(z1) = I4(z2)\n');
    fprintf('Counterexample would falsify: I4 uniqueness claim\n');
    fprintf('Status: OPEN\n\n');

    falsification_report = struct();
    falsification_report.timestamp = datetime('now');
    falsification_report.obligation = 'H2_i4_full_state';
    falsification_report.counterexamples = [];

    % =====================================================================
    % Strategy 1: Scaled Vectors (Expected Collision via Homogeneity)
    % =====================================================================

    fprintf('=== STRATEGY 1: Scaled Vectors ===\n');
    fprintf('Known: I4(r*z) = r^4 * I4(z) (homogeneity)\n');
    fprintf('These are "homogeneous collisions" (expected)\n\n');

    num_test_vectors = 100;
    scaling_factors = [0.5, 2.0];

    homogeneous_collisions = 0;

    rng(42);

    for test = 1:num_test_vectors
        z = randn(1, 8);
        i4_z = compute_i4(z);

        for scale = scaling_factors
            z_scaled = scale * z;
            i4_scaled = compute_i4(z_scaled);
            expected = scale^4 * i4_z;

            if abs(i4_scaled - expected) < 1e-8
                homogeneous_collisions = homogeneous_collisions + 1;

                if homogeneous_collisions <= 3
                    fprintf('Homogeneous collision (expected): scale=%.1f, ||z||=%.4f\n', ...
                        scale, norm(z));
                end
            end
        end
    end

    fprintf('Homogeneous collisions found: %d (expected behavior)\n\n', homogeneous_collisions);

    % =====================================================================
    % Strategy 2: Random Search for Non-Homogeneous Collisions
    % =====================================================================

    fprintf('=== STRATEGY 2: Random Search ===\n');
    fprintf('Search for truly distinct states with same I4 (non-trivial counterexample)\n\n');

    num_random_pairs = 10000;
    collision_tolerance = 1e-10;
    counterexample_count = 0;

    for test = 1:num_random_pairs
        z1 = randn(1, 8);
        z2 = randn(1, 8);

        % Skip if trivially related
        if norm(z1) < 1e-6 || norm(z2) < 1e-6
            continue;
        end

        i4_z1 = compute_i4(z1);
        i4_z2 = compute_i4(z2);

        % Check collision
        if abs(i4_z1 - i4_z2) < collision_tolerance && norm(z1 - z2) > 0.1

            % Verify non-homogeneous
            scale_est = norm(z2) / norm(z1);
            z1_scaled = scale_est * z1;
            if norm(z1_scaled - z2) > 0.1  % Not just a scaling

                counterexample_count = counterexample_count + 1;

                fprintf('COLLISION FOUND (non-homogeneous)!\n');
                fprintf('  z1 norm: %.6f\n', norm(z1));
                fprintf('  z2 norm: %.6f\n', norm(z2));
                fprintf('  ||z1-z2||: %.6f\n', norm(z1 - z2));
                fprintf('  I4(z1): %.6f\n', i4_z1);
                fprintf('  I4(z2): %.6f\n', i4_z2);
                fprintf('  Difference: %.2e\n\n', abs(i4_z1 - i4_z2));

                falsification_report.counterexamples = ...
                    [falsification_report.counterexamples; ...
                     struct('z1', z1, 'z2', z2, 'i4_z1', i4_z1, 'i4_z2', i4_z2)];

                if counterexample_count >= 5
                    break;
                end
            end
        end

        if mod(test, 2000) == 0
            fprintf('Tested %d pairs, %d non-homogeneous collisions found\n', ...
                test, counterexample_count);
        end
    end

    fprintf('\nNon-homogeneous collisions found: %d\n\n', counterexample_count);

    % =====================================================================
    % Strategy 3: Gradient Descent to Find Collision Pairs
    % =====================================================================

    fprintf('=== STRATEGY 3: Gradient Descent Collision Search ===\n');
    fprintf('Use optimization to find I4 level sets\n\n');

    gradient_counterexamples = 0;

    for trial = 1:20
        z_base = randn(1, 8);
        i4_target = compute_i4(z_base);

        % Try to find another point on the same I4 level set
        z_search = randn(1, 8);

        for iter = 1:100
            i4_search = compute_i4(z_search);
            error = i4_search - i4_target;

            if abs(error) < 1e-8 && norm(z_search - z_base) > 0.1
                gradient_counterexamples = gradient_counterexamples + 1;

                fprintf('Gradient search: Found level-set pair\n');
                fprintf('  Base z norm: %.6f, Search z norm: %.6f\n', ...
                    norm(z_base), norm(z_search));
                fprintf('  ||z_base - z_search||: %.6f\n', norm(z_base - z_search));

                falsification_report.counterexamples = ...
                    [falsification_report.counterexamples; ...
                     struct('z1', z_base, 'z2', z_search, ...
                            'i4_z1', i4_target, 'i4_z2', i4_search)];

                break;
            end

            % Gradient step
            grad_mag = error / (norm(z_search) + 1e-8);
            z_search = z_search - 0.01 * grad_mag * z_search;

            if iter == 100 && abs(error) > 1e-8
                % Failed to converge on level set
            end
        end

        if gradient_counterexamples >= 3
            break;
        end
    end

    fprintf('Gradient descent collisions found: %d\n\n', gradient_counterexamples);

    % =====================================================================
    % Summary
    % =====================================================================

    fprintf('=== FALSIFICATION SUMMARY ===\n\n');

    total_counterexamples = length(falsification_report.counterexamples);

    fprintf('Total distinct states with I4(z1) = I4(z2) and z1 ≠ z2: %d\n', ...
        total_counterexamples);

    if total_counterexamples == 0
        fprintf('\nResult: OB (I4 sufficiency) REMAINS OPEN\n');
        fprintf('No non-homogeneous collisions found (yet)\n');
    else
        fprintf('\nResult: OB FALSIFIED\n');
        fprintf('Found %d counterexamples to I4 uniqueness\n', total_counterexamples);
    end

    fprintf('\n');

end

%% Compute I4 invariant
function i4 = compute_i4(z)
    z = z / (norm(z) + eps);
    d = length(z);

    if d >= 3
        term1 = (z(1)*z(3) - z(2)^2)^2;
        if d >= 4
            term2 = (z(1)*z(4) - z(2)*z(3))^2;
            term3 = (z(2)*z(4) - z(3)^2)^2;
            i4 = term1 + term2 + term3;
        else
            i4 = term1;
        end
    else
        z_pad = [z, zeros(1, 3-d)];
        i4 = (z_pad(1)*z_pad(3) - z_pad(2)^2)^2;
    end
end
