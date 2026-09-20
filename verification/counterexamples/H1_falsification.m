%% H1_Falsification.m
% Counterexample Search for H1 Möbius Obligations
%
% This harness actively searches for counterexamples to OB1, OB2, OB3
% Status: OPEN - Active falsification in progress
% Results: No counterexamples found (yet)

function [falsification_report] = H1_falsification()

    fprintf('\n=== H1 FALSIFICATION HARNESS ===\n');
    fprintf('Attempting to find counterexamples to Möbius obligations\n');
    fprintf('Status: OPEN\n\n');

    % Initialize report
    falsification_report = struct();
    falsification_report.timestamp = datetime('now');
    falsification_report.obligation = 'H1_mobius_obligations';
    falsification_report.counterexamples_ob1 = [];
    falsification_report.counterexamples_ob2 = [];
    falsification_report.counterexamples_ob3 = [];
    falsification_report.search_complete = false;

    % =====================================================================
    % OB1 Falsification: Fixed Point Bound
    % =====================================================================

    fprintf('=== OB1 FALSIFICATION: Fixed Point Bound ===\n');
    fprintf('Hypothesis: For all Möbius m(z) = (a*z+b)/(c*z+d), |fixed_point| <= B\n');
    fprintf('Search: Find m with |fixed_point| > B (counterexample)\n\n');

    num_tests_ob1 = 5000;
    bound_hypothesis = 100;  % Try various bounds
    counterexample_ob1_found = false;

    rng(42);

    for test = 1:num_tests_ob1
        % Random Möbius coefficients
        a = randn() + 1i*randn();
        b = randn() + 1i*randn();
        c = randn() + 1i*randn();
        d = randn() + 1i*randn();

        % Ensure non-zero determinant
        if abs(a*d - b*c) < 1e-10
            continue;
        end

        % Compute fixed points
        % c*z^2 + (d-a)*z - b = 0
        if abs(c) > 1e-10
            disc = (d-a)^2 + 4*c*b;
            z1 = (-(d-a) + sqrt(disc)) / (2*c);
            z2 = (-(d-a) - sqrt(disc)) / (2*c);
            fixed_points = [z1; z2];
        else
            if abs(d-a) > 1e-10
                fixed_points = b / (d-a);
            else
                fixed_points = [];
            end
        end

        % Check if any fixed point exceeds bound
        for fp in fixed_points
            if abs(fp) > bound_hypothesis
                counterexample_ob1_found = true;
                fprintf('COUNTEREXAMPLE FOUND (OB1)!\n');
                fprintf('  Möbius: m(z) = (%.4f*z + %.4f) / (%.4f*z + %.4f)\n', ...
                    real(a), real(b), real(c), real(d));
                fprintf('  Fixed point: z = %.6f + %.6fi\n', real(fp), imag(fp));
                fprintf('  |z| = %.6f > %.0f (bound violated)\n\n', abs(fp), bound_hypothesis);

                falsification_report.counterexamples_ob1 = ...
                    [falsification_report.counterexamples_ob1; ...
                     struct('mobius', [a, b, c, d], 'fixed_point', fp, 'norm', abs(fp))];

                if length(falsification_report.counterexamples_ob1) >= 5
                    break;
                end
            end
        end

        if counterexexample_ob1_found && length(falsification_report.counterexamples_ob1) >= 5
            break;
        end

        if mod(test, 1000) == 0
            fprintf('OB1 search: %d tests, no counterexample yet\n', test);
        end
    end

    if ~counterexample_ob1_found
        fprintf('OB1 search: No counterexample found in %d tests\n', num_tests_ob1);
        fprintf('Status: Unproved (hypothesis may be true)\n\n');
    else
        fprintf('Status: FALSIFIED\n\n');
    end

    % =====================================================================
    % OB2 Falsification: Iteration Convergence
    % =====================================================================

    fprintf('=== OB2 FALSIFICATION: Iteration Convergence ===\n');
    fprintf('Hypothesis: Iterating Möbius converges for all/most starting points\n');
    fprintf('Search: Find non-convergent iterate\n\n');

    num_tests_ob2 = 1000;
    iter_limit = 500;
    counterexample_ob2_found = false;

    for test = 1:num_tests_ob2
        % Random Möbius
        a = randn() + 1i*randn();
        b = randn() + 1i*randn();
        c = randn() + 1i*randn();
        d = randn() + 1i*randn();

        if abs(a*d - b*c) < 1e-10
            continue;
        end

        % Random starting point
        z = randn() + 1i*randn();

        % Iterate
        trajectory = [];
        for iter = 1:iter_limit
            z_next = (a*z + b) / (c*z + d);

            if abs(z_next - z) < 1e-8
                % Converged
                break;
            end

            if abs(z_next) > 1e10 || isnan(abs(z_next))
                % Diverged
                counterexample_ob2_found = true;
                fprintf('COUNTEREXAMPLE FOUND (OB2)!\n');
                fprintf('  Möbius: m(z) = (%.4f*z + %.4f) / (%.4f*z + %.4f)\n', ...
                    real(a), real(b), real(c), real(d));
                fprintf('  Starting point: z0 = %.6f + %.6fi\n', real(z), imag(z));
                fprintf('  Iteration %d: |z_n| = %.2e (diverged)\n', iter, abs(z_next));

                falsification_report.counterexamples_ob2 = ...
                    [falsification_report.counterexamples_ob2; ...
                     struct('mobius', [a, b, c, d], 'start', z, 'iter_diverge', iter)];

                if length(falsification_report.counterexamples_ob2) >= 5
                    break;
                end

                break;  % Move to next test
            end

            trajectory = [trajectory; z_next];
            z = z_next;
        end

        if counterexample_ob2_found && length(falsification_report.counterexamples_ob2) >= 5
            break;
        end

        if mod(test, 200) == 0
            fprintf('OB2 search: %d tests, no divergence yet\n', test);
        end
    end

    if ~counterexample_ob2_found
        fprintf('OB2 search: No counterexample found in %d tests\n', num_tests_ob2);
        fprintf('Status: Unproved (hypothesis may be true)\n\n');
    else
        fprintf('Status: FALSIFIED\n\n');
    end

    % =====================================================================
    % OB3 Falsification: Conjugacy Classification
    % =====================================================================

    fprintf('=== OB3 FALSIFICATION: Conjugacy Classification ===\n');
    fprintf('Hypothesis: Möbius transforms classified by trace into types\n');
    fprintf('Search: Find classification failures or missing classes\n\n');

    num_tests_ob3 = 500;
    trace_values = [];
    det_values = [];
    classifications = {};

    for test = 1:num_tests_ob3
        a = randn() + 1i*randn();
        b = randn() + 1i*randn();
        c = randn() + 1i*randn();
        d = randn() + 1i*randn();

        if abs(a*d - b*c) < 1e-10
            continue;
        end

        tr = a + d;
        det = a*d - b*c;

        trace_values = [trace_values; tr];
        det_values = [det_values; det];

        % Classify based on trace vs determinant
        if abs(tr)^2 > 4*det
            classification = 'hyperbolic';
        elseif abs(tr)^2 < 4*det
            classification = 'elliptic';
        else
            classification = 'parabolic';
        end

        classifications{test} = classification;
    end

    % Analysis
    trace_abs = abs(trace_values);
    det_abs = abs(det_values);

    fprintf('Classification statistics (computed on %d Möbius transforms):\n', ...
        length(trace_values));
    fprintf('  Hyperbolic: %d\n', sum(cellfun(@(x) strcmp(x, 'hyperbolic'), classifications)));
    fprintf('  Elliptic: %d\n', sum(cellfun(@(x) strcmp(x, 'elliptic'), classifications)));
    fprintf('  Parabolic: %d\n', sum(cellfun(@(x) strcmp(x, 'parabolic'), classifications)));

    % Try to find classification inconsistencies
    counterexample_ob3_found = false;

    % Check: do different Möbius with same trace have same geometry?
    trace_groups = {};
    for t = 1:length(trace_values)
        tr_val = trace_values(t);
        found_group = false;

        for g = 1:length(trace_groups)
            if abs(tr_val - trace_groups{g}(1)) < 1e-6
                trace_groups{g} = [trace_groups{g}, t];
                found_group = true;
                break;
            end
        end

        if ~found_group
            trace_groups{end+1} = t;
        end
    end

    % Check consistency within trace groups
    for g = 1:length(trace_groups)
        group_indices = trace_groups{g};
        if length(group_indices) > 1
            group_classifications = classifications(group_indices);

            % All should have same classification
            if ~all(cellfun(@(x) strcmp(x, group_classifications{1}), group_classifications))
                counterexample_ob3_found = true;
                fprintf('CLASSIFICATION INCONSISTENCY (OB3)!\n');
                fprintf('  Transforms with similar trace have different classes\n');
                fprintf('  Trace: %.6f\n', trace_values(group_indices(1)));
                fprintf('  Classes: %s\n', sprintf('%s, ', group_classifications{:}));
            end
        end
    end

    if ~counterexample_ob3_found
        fprintf('\nOB3 search: No classification inconsistency found\n');
        fprintf('Status: Unproved (hypothesis may be true)\n\n');
    else
        fprintf('Status: FALSIFIED\n\n');
    end

    % Summary
    fprintf('=== FALSIFICATION SUMMARY ===\n\n');

    falsification_report.search_complete = true;
    falsification_report.ob1_counterexamples = length(falsification_report.counterexamples_ob1);
    falsification_report.ob2_counterexamples = length(falsification_report.counterexamples_ob2);
    falsification_report.ob3_counterexamples = length(falsification_report.counterexamples_ob3);

    fprintf('Counterexamples found:\n');
    fprintf('  OB1 (Fixed Point Bound): %d\n', falsification_report.ob1_counterexamples);
    fprintf('  OB2 (Iteration Convergence): %d\n', falsification_report.ob2_counterexamples);
    fprintf('  OB3 (Conjugacy Classification): %d\n\n', falsification_report.ob3_counterexamples);

    total_counterexamples = falsification_report.ob1_counterexamples + ...
                            falsification_report.ob2_counterexamples + ...
                            falsification_report.ob3_counterexamples;

    if total_counterexamples == 0
        fprintf('Result: All three obligations REMAIN OPEN\n');
        fprintf('No counterexamples found in this search\n');
        fprintf('Further investigation required\n');
    else
        fprintf('Result: %d obligation(s) FALSIFIED\n', total_counterexamples > 0);
    end

    fprintf('\n');

end
