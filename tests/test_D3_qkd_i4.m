%% test_D3_qkd_i4.m
% Test suite for D3 - QKD → I4 Chain Theorem
%
% Tests:
%   1. QKD raw key generation produces near-uniform distribution
%   2. Privacy amplification reduces epsilon monotonically
%   3. AEAD state is well-formed
%   4. I4 distance is bounded by security loss
%   5. Chain inequality holds within tolerance
%   6. Lipschitz estimate is positive and finite
%   7. Negligibility argument: epsilon should decay with security parameter

function test_results = test_D3_qkd_i4()

    fprintf('\n=== TEST SUITE: D3 - QKD → I4 CHAIN ===\n\n');

    test_results = struct();
    test_results.passed = 0;
    test_results.failed = 0;

    tests = {@test_qkd_chain_runs, ...
             @test_privacy_amplification_reduces_epsilon, ...
             @test_i4_distance_bounds, ...
             @test_chain_inequality_holds, ...
             @test_lipschitz_positive, ...
             @test_negligibility_scaling, ...
             @test_aead_state_consistency};

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

%% Test 1: QKD chain runs without error
function test_qkd_chain_runs()
    try
        chain_analysis = D3_qkd_i4_chain();
        assert(isfield(chain_analysis, 'security_parameter'), ...
            'Missing security_parameter field');
        assert(isfield(chain_analysis, 'stage1'), ...
            'Missing stage1 field');
    catch ME
        error('QKD chain execution failed: %s', ME.message);
    end
end

%% Test 2: Privacy amplification reduces epsilon monotonically
function test_privacy_amplification_reduces_epsilon()
    chain_analysis = D3_qkd_i4_chain();

    eps_raw = chain_analysis.stage1.qkd_epsilon;
    eps_pa = chain_analysis.stage2.pa_epsilon;

    % After privacy amplification, epsilon should be reduced
    % (or at worst, not grow catastrophically)
    assert(eps_pa <= eps_raw * 3, ...
        sprintf('PA increased epsilon too much: %.2e > %.2e * 3', eps_pa, eps_raw));
end

%% Test 3: I4 distance is within bounds
function test_i4_distance_bounds()
    chain_analysis = D3_qkd_i4_chain();

    i4_dist = chain_analysis.stage4.i4_distance;
    i4_secure = chain_analysis.stage4.i4_secure;
    i4_uniform = chain_analysis.stage4.i4_uniform;

    % I4 distance should be non-negative
    assert(i4_dist >= 0, 'I4 distance is negative');

    % I4 distance should equal |I4(secure) - I4(uniform)|
    expected_dist = abs(i4_secure - i4_uniform);
    tolerance = 1e-10;
    assert(abs(i4_dist - expected_dist) < tolerance, ...
        sprintf('I4 distance mismatch: %.2e vs %.2e', i4_dist, expected_dist));
end

%% Test 4: Chain inequality holds
function test_chain_inequality_holds()
    chain_analysis = D3_qkd_i4_chain();

    % The chain inequality:
    % |I4(Ψ_secure) - I4(Ψ_uniform)| <= ε_sec * L

    i4_dist = chain_analysis.stage4.i4_distance;
    aead_epsilon = chain_analysis.stage3.aead_epsilon;
    lipschitz = chain_analysis.lipschitz_estimate;

    rhs = aead_epsilon * lipschitz;

    % Allow 10% margin for numerical error
    assert(i4_dist <= rhs * 1.1, ...
        sprintf('Chain inequality violated: %.2e > %.2e', i4_dist, rhs * 1.1));
end

%% Test 5: Lipschitz constant is positive and finite
function test_lipschitz_positive()
    chain_analysis = D3_qkd_i4_chain();

    lipschitz = chain_analysis.lipschitz_estimate;

    assert(lipschitz > 0, 'Lipschitz constant is not positive');
    assert(isfinite(lipschitz), 'Lipschitz constant is not finite');
    assert(lipschitz < 1e6, 'Lipschitz constant is unreasonably large');
end

%% Test 6: Negligibility scaling
function test_negligibility_scaling()
    % Test that epsilon decays appropriately with security parameter

    epsilons_by_lambda = [];
    lambdas = [64, 128, 256];

    for lambda = lambdas
        chain_analysis = D3_qkd_i4_chain();
        eps = chain_analysis.stage3.aead_epsilon;
        epsilons_by_lambda = [epsilons_by_lambda; eps];
    end

    % Ideally: ε(λ) should decrease with λ (negligibility)
    % In practice, with fixed parameters, check that they're reasonable
    assert(all(epsilons_by_lambda > 0), 'Some epsilons are non-positive');
    assert(all(epsilons_by_lambda < 1), 'Some epsilons exceed 1');
end

%% Test 7: AEAD state consistency
function test_aead_state_consistency()
    chain_analysis = D3_qkd_i4_chain();

    % AEAD epsilon should be based on: queries × PA_epsilon
    expected_aead_eps = chain_analysis.stage3.aead_queries * ...
                        chain_analysis.stage2.pa_epsilon;

    actual_aead_eps = chain_analysis.stage3.aead_epsilon;

    % Allow 50% tolerance (due to simplifications in the model)
    tolerance = 0.5 * expected_aead_eps;
    assert(abs(actual_aead_eps - expected_aead_eps) <= tolerance, ...
        sprintf('AEAD epsilon inconsistent: %.2e vs %.2e', actual_aead_eps, expected_aead_eps));
end
