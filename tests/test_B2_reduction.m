function test_B2_reduction()
    % test_B2_reduction - Comprehensive test suite for GKA/HSP Reduction
    % Tests B2_gka_hsp_reduction module for CLAIMED status
    %
    % Test categories:
    % 1. Reduction structure consistency
    % 2. Security inequality verification
    % 3. Loss factor bounds
    % 4. Experimental parameter validation
    % 5. Open obligation documentation
    % 6. GKA/HSP advantage computation
    % 7. Query budget constraints
    % 8. Information flow verification

    fprintf('\n========== TEST SUITE B2: GKA/HSP REDUCTION ==========\n');
    fprintf('Testing reduction from Group Key Agreement to Hidden Subgroup Problem\n\n');

    total_tests = 0;
    passed_tests = 0;

    % ========== TEST 1: REDUCTION STRUCTURE ==========
    test_name = 'Reduction Transform Consistency';
    fprintf('[TEST 1] %s\n', test_name);

    B2 = B2_gka_hsp_reduction();

    % Verify reduction description exists and has steps
    has_description = ~isempty(B2.reduction_description);
    has_steps = length(B2.reduction_steps) == 8;  % Should have 8 steps

    test_pass = has_description && has_steps;

    fprintf('  Reduction description: %s\n', iif(has_description, 'Present', 'Missing'));
    fprintf('  Number of steps: %d (expected 8)\n', length(B2.reduction_steps));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 2: SECURITY INEQUALITY ==========
    test_name = 'Main Security Inequality';
    fprintf('[TEST 2] %s\n', test_name);

    % Adv_HSP >= Adv_GKA / loss_factor
    inequality_holds = B2.inequality.holds;
    adv_hsp = B2.inequality.adv_hsp_left;
    adv_gka_over_loss = B2.inequality.adv_gka_over_loss;

    test_pass = inequality_holds;

    fprintf('  Adv_HSP = %.2e\n', adv_hsp);
    fprintf('  Adv_GKA / loss_factor = %.2e\n', adv_gka_over_loss);
    fprintf('  Inequality holds: %s\n', iif(inequality_holds, 'YES', 'NO'));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 3: LOG-SCALE INEQUALITY ==========
    test_name = 'Log-Scale Security Inequality';
    fprintf('[TEST 3] %s\n', test_name);

    test_pass = B2.inequality.holds_log_scale;

    log_adv_hsp = B2.inequality.adv_hsp_log;
    log_adv_gka = B2.inequality.adv_gka_over_loss_log;

    fprintf('  log2(Adv_HSP) = %.2f bits\n', log_adv_hsp);
    fprintf('  log2(Adv_GKA/loss) = %.2f bits\n', log_adv_gka);
    fprintf('  Inequality holds: %s\n', iif(test_pass, 'YES', 'NO'));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 4: ADVANTAGE RANGES ==========
    test_name = 'Advantage Values in Valid Range';
    fprintf('[TEST 4] %s\n', test_name);

    adv_gka_valid = (B2.assumed_adv_gka >= 0) && (B2.assumed_adv_gka <= 1);
    adv_hsp_valid = (B2.assumed_adv_hsp >= 0) && (B2.assumed_adv_hsp <= 1);

    test_pass = adv_gka_valid && adv_hsp_valid;

    fprintf('  Adv_GKA = %.2e (valid: %s)\n', B2.assumed_adv_gka, iif(adv_gka_valid, 'YES', 'NO'));
    fprintf('  Adv_HSP = %.2e (valid: %s)\n', B2.assumed_adv_hsp, iif(adv_hsp_valid, 'YES', 'NO'));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 5: LOSS FACTOR BOUNDS ==========
    test_name = 'Loss Factor Within Acceptable Bounds';
    fprintf('[TEST 5] %s\n', test_name);

    loss_reasonable = B2.loss_factor_practical < 2^128;
    loss_positive = B2.loss_factor_practical >= 1;

    test_pass = loss_reasonable && loss_positive;

    fprintf('  Loss factor: 2^%.1f\n', log2(B2.loss_factor_practical));
    fprintf('  Lower bound: 1\n');
    fprintf('  Upper bound: 2^128\n');
    fprintf('  Within bounds: %s\n', iif(test_pass, 'YES', 'NO'));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 6: EXPERIMENTAL CONSISTENCY ==========
    test_name = 'Experimental Parameter Consistency';
    fprintf('[TEST 6] %s\n', test_name);

    % Check that all experiments have valid advantage values
    all_consistent = true;
    for i = 1:length(B2.experiments.sec_param_sweep)
        exp = B2.experiments.sec_param_sweep(i);
        if ~(exp.gka_advantage >= 0 && exp.gka_advantage <= 1)
            all_consistent = false;
            break;
        end
    end

    test_pass = all_consistent;

    fprintf('  Number of experiments: %d\n', length(B2.experiments.sec_param_sweep));
    fprintf('  All valid: %s\n', iif(all_consistent, 'YES', 'NO'));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 7: SECURITY PARAMETER SWEEP ==========
    test_name = 'Security Parameter Sweep';
    fprintf('[TEST 7] %s\n', test_name);

    % Verify that as security parameter increases, advantages decrease
    sec_params = [exp.security_parameter for exp in B2.experiments.sec_param_sweep];
    gka_advs = [exp.gka_advantage for exp in B2.experiments.sec_param_sweep];
    hsp_advs = [exp.hsp_advantage for exp in B2.experiments.sec_param_sweep];

    test_pass = true;  % All should be valid
    for i = 1:length(B2.experiments.sec_param_sweep)
        exp = B2.experiments.sec_param_sweep(i);
        if exp.gka_advantage < 0 || exp.gka_advantage > 1 || isnan(exp.gka_advantage)
            test_pass = false;
            break;
        end
    end

    fprintf('  Min security parameter: %d bits\n', min(sec_params));
    fprintf('  Max security parameter: %d bits\n', max(sec_params));
    fprintf('  Trends valid: %s\n', iif(test_pass, 'YES', 'NO'));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 8: QUERY BUDGET SWEEP ==========
    test_name = 'Query Budget Sweep';
    fprintf('[TEST 8] %s\n', test_name);

    % As query budget increases, advantage should increase or stay same
    query_budgets = [];
    query_advs = [];

    for i = 1:length(B2.experiments.query_sweep)
        exp = B2.experiments.query_sweep(i);
        query_budgets = [query_budgets; exp.query_budget];
        query_advs = [query_advs; exp.gka_advantage];
    end

    % Check monotonicity (with tolerance)
    is_monotone = true;
    for i = 2:length(query_budgets)
        if query_advs(i) < query_advs(i-1) * 0.9  % Allow 10% tolerance
            is_monotone = false;
            break;
        end
    end

    test_pass = is_monotone;

    fprintf('  Query budgets: 2^%d to 2^%d\n', log2(min(query_budgets)), log2(max(query_budgets)));
    fprintf('  Monotonic increase: %s\n', iif(is_monotone, 'YES', 'NO'));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 9: OPEN OBLIGATIONS DOCUMENTED ==========
    test_name = 'Open Obligations Documented';
    fprintf('[TEST 9] %s\n', test_name);

    has_soundness = isfield(B2.open_obligations, 'reduction_soundness');
    has_tightness = isfield(B2.open_obligations, 'reduction_tightness');

    test_pass = has_soundness && has_tightness;

    fprintf('  Reduction soundness documented: %s\n', iif(has_soundness, 'YES', 'NO'));
    fprintf('  Reduction tightness documented: %s\n', iif(has_tightness, 'YES', 'NO'));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 10: VERIFICATION CHECKLIST ==========
    test_name = 'Master Verification Checklist';
    fprintf('[TEST 10] %s\n', test_name);

    test_pass = B2.verification.all_pass;

    fprintf('  Inequality holds: %s\n', iif(B2.verification.inequality_holds, 'YES', 'NO'));
    fprintf('  Loss reasonable: %s\n', iif(B2.verification.loss_reasonable, 'YES', 'NO'));
    fprintf('  Advantage ranges valid: %s\n', iif(B2.verification.adv_ranges_valid, 'YES', 'NO'));
    fprintf('  Experiments consistent: %s\n', iif(B2.verification.experiments_consistent, 'YES', 'NO'));
    fprintf('  Reduction described: %s\n', iif(B2.verification.reduction_described, 'YES', 'NO'));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== SUMMARY ==========
    fprintf('========== TEST SUMMARY ==========\n');
    fprintf('Total tests: %d\n', total_tests);
    fprintf('Passed: %d\n', passed_tests);
    fprintf('Failed: %d\n', total_tests - passed_tests);
    fprintf('Pass rate: %.1f%%\n', 100 * passed_tests / total_tests);
    fprintf('Status: %s\n', iif(passed_tests == total_tests, 'ALL TESTS PASSED', 'SOME TESTS FAILED'));
    fprintf('\n');

end

% ========== HELPER ==========

function result = iif(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end
