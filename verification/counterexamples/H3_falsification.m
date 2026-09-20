%% H3_Falsification.m
% Counterexample Search for H3 QKD → I4 Chain
%
% This harness searches for violations of the chain: QKD secure ⇒ I4 property
% Status: OPEN - Active falsification in progress

function [falsification_report] = H3_falsification()

    fprintf('\n=== H3 FALSIFICATION HARNESS ===\n');
    fprintf('Seeking: QKD-secure states where I4 property fails\n');
    fprintf('Counterexample would falsify: Chain completeness\n');
    fprintf('Status: OPEN\n\n');

    falsification_report = struct();
    falsification_report.timestamp = datetime('now');
    falsification_report.obligation = 'H3_qkd_i4_chain_open';
    falsification_report.chain_violations = [];
    falsification_report.loss_violations = [];

    % =====================================================================
    % Loss Bound Violation Search
    % =====================================================================

    fprintf('=== LOSS BOUND ANALYSIS ===\n');
    fprintf('OB_loss_bounds: security_loss ≤ negligible(λ)\n');
    fprintf('Search for cases where loss is non-negligible\n\n');

    lambda = 128;
    negligible_threshold = 2^(-lambda/2);

    num_protocols = 200;
    loss_violations = 0;

    rng(42);

    for protocol = 1:num_protocols
        % QKD security loss (epsilon_sec)
        epsilon_sec = 2^(-lambda) * (1 + 0.1*randn());  % nominal

        % Privacy amplification loss (multiplied by privacy amp rounds)
        privacy_rounds = 256;
        epsilon_pa = privacy_rounds * epsilon_sec;

        % AEAD loss
        epsilon_aead = 2 * epsilon_pa;

        % I4 chain loss
        epsilon_chain = 3 * epsilon_aead;

        % Total loss
        total_loss = epsilon_chain;

        if total_loss > negligible_threshold
            loss_violations = loss_violations + 1;

            if loss_violations <= 3
                fprintf('Loss bound violated:\n');
                fprintf('  ε_sec: %.2e\n', epsilon_sec);
                fprintf('  After privacy amp: %.2e\n', epsilon_pa);
                fprintf('  After AEAD: %.2e\n', epsilon_aead);
                fprintf('  After I4 chain: %.2e\n', total_loss);
                fprintf('  Threshold: %.2e\n', negligible_threshold);
                fprintf('  Ratio: %.2f\n\n', total_loss / negligible_threshold);
            end

            falsification_report.loss_violations = ...
                [falsification_report.loss_violations; ...
                 struct('epsilon_sec', epsilon_sec, 'total_loss', total_loss, ...
                        'threshold', negligible_threshold)];
        end
    end

    fprintf('Loss bound violations: %d / %d\n\n', loss_violations, num_protocols);

    % =====================================================================
    % Chain Sufficiency Violation Search
    % =====================================================================

    fprintf('=== CHAIN SUFFICIENCY ANALYSIS ===\n');
    fprintf('OB_chain_sufficiency: QKD secure ⟹ I4 property holds\n');
    fprintf('Search for counterexample\n\n');

    chain_violations = 0;

    for test = 1:100
        % Generate "QKD-secure" state (simulated)
        qkd_state = randn(1, 128);
        qkd_state = qkd_state / norm(qkd_state);  % normalize

        % Apply privacy amplification
        % (Toeplitz matrix multiplication)
        toeplitz_bits = rand(128, 1) > 0.5;
        psi_pa = toeplitz_bits .* qkd_state';

        % Apply AEAD encryption
        nonce = randn(1, 16);
        aead_encrypted = psi_pa + 0.01*nonce';

        % Check I4 property on AEAD state
        i4_before = compute_i4(psi_pa(1:8)');
        i4_after = compute_i4(aead_encrypted(1:8));

        % Check I4 homogeneity preservation
        scale = 0.5;
        i4_scaled = compute_i4(scale * aead_encrypted(1:8));
        expected = scale^4 * i4_after;

        if abs(i4_scaled - expected) > 1e-6
            chain_violations = chain_violations + 1;

            fprintf('Chain violation:\n');
            fprintf('  I4 homogeneity not preserved\n');
            fprintf('  I4(0.5*ψ) = %.6f\n', i4_scaled);
            fprintf('  Expected = %.6f\n', expected);
            fprintf('  Error: %.2e\n\n', abs(i4_scaled - expected));

            falsification_report.chain_violations = ...
                [falsification_report.chain_violations; ...
                 struct('psi_before', psi_pa(1:8)', 'psi_after', aead_encrypted(1:8), ...
                        'i4_before', i4_before, 'i4_after', i4_after, ...
                        'homogeneity_error', abs(i4_scaled - expected))];
        end
    end

    fprintf('Chain sufficiency violations: %d / 100\n\n', chain_violations);

    % =====================================================================
    % Security Parameter Sensitivity
    % =====================================================================

    fprintf('=== SECURITY PARAMETER SENSITIVITY ===\n');
    fprintf('Varying λ: does loss scale properly?\n\n');

    lambdas = [64, 128, 256, 512];
    scaling_violations = 0;

    for lambda = lambdas
        neg_threshold = 2^(-lambda/2);
        epsilon_base = 2^(-lambda);

        % Loss scales with privacy amplification
        loss = 256 * epsilon_base * 2 * 3;

        if loss > neg_threshold
            scaling_violations = scaling_violations + 1;
            fprintf('λ=%d: loss=%.2e, threshold=%.2e (VIOLATION)\n', ...
                lambda, loss, neg_threshold);
        else
            fprintf('λ=%d: loss=%.2e, threshold=%.2e (ok)\n', ...
                lambda, loss, neg_threshold);
        end
    end

    fprintf('\n');

    % =====================================================================
    % Summary
    % =====================================================================

    fprintf('=== FALSIFICATION SUMMARY ===\n\n');

    total_violations = length(falsification_report.loss_violations) + ...
                       length(falsification_report.chain_violations);

    fprintf('Loss bound violations: %d\n', length(falsification_report.loss_violations));
    fprintf('Chain sufficiency violations: %d\n', length(falsification_report.chain_violations));
    fprintf('Total violations: %d\n\n', total_violations);

    if total_violations == 0
        fprintf('Result: Both obligations REMAIN OPEN\n');
        fprintf('No violations found in this search\n');
        fprintf('Further investigation required\n');
    else
        fprintf('Result: %d obligation(s) potentially FALSIFIED\n', total_violations > 0);
        fprintf('Further verification needed\n');
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
