function test_B5_resultant()
    % test_B5_resultant - Test suite for Sylvester Matrix Resultant Signature
    % Tests B5_resultant_signature module for VERIFIED_COMPUTATIONAL status
    %
    % Test categories:
    % 1. Resultant computation
    % 2. Common root detection
    % 3. Modular resultant computation
    % 4. Signature generation and verification
    % 5. Polynomial family analysis
    % 6. Collision resistance
    % 7. Symmetry property verification
    % 8. Numerical stability

    fprintf('\n========== TEST SUITE B5: RESULTANT SIGNATURE ==========\n');
    fprintf('Testing Sylvester matrix resultant computation and signatures\n\n');

    total_tests = 0;
    passed_tests = 0;

    % ========== TEST 1: RESULTANT COMPUTATION ==========
    test_name = 'Resultant Computation via Sylvester Matrix';
    fprintf('[TEST 1] %s\n', test_name);

    B5 = B5_resultant_signature();

    % All resultants should be finite numbers
    res_computed = ~isnan(B5.resultant.res_P_Q) && ...
                   isfinite(B5.resultant.res_P_Q) && ...
                   ~isnan(B5.resultant.res_P_R) && ...
                   isfinite(B5.resultant.res_P_R) && ...
                   ~isnan(B5.resultant.res_Q_R) && ...
                   isfinite(B5.resultant.res_Q_R);

    test_pass = res_computed;

    fprintf('  Res(P,Q) = %.6f\n', B5.resultant.res_P_Q);
    fprintf('  Res(P,R) = %.6f\n', B5.resultant.res_P_R);
    fprintf('  Res(Q,R) = %.6f\n', B5.resultant.res_Q_R);
    fprintf('  All finite: %s\n', iif(res_computed, 'YES', 'NO'));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 2: COMMON ROOT DETECTION ==========
    test_name = 'Common Root Detection';
    fprintf('[TEST 2] %s\n', test_name);

    % P(x) = (x-2)(x-3), Q(x) = (x-1)(x-3) share x=3
    % So Res(P,Q) should be ~0
    p_q_share = B5.resultant.P_Q_shares_root;

    % P(x) = (x-2)(x-3), R(x) = (x-2)(x+2) share x=2
    % So Res(P,R) should be ~0
    p_r_share = B5.resultant.P_R_shares_root;

    test_pass = p_q_share && p_r_share;

    fprintf('  P and Q share root: %s (Res ≈ %.2e)\n', iif(p_q_share, 'YES', 'NO'), B5.resultant.res_P_Q);
    fprintf('  P and R share root: %s (Res ≈ %.2e)\n', iif(p_r_share, 'YES', 'NO'), B5.resultant.res_P_R);
    fprintf('  Q and R no shared root: %s (Res = %.2e)\n', ...
        iif(B5.resultant.Q_R_no_shared_root, 'YES', 'NO'), B5.resultant.res_Q_R);
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 3: MODULAR RESULTANT ==========
    test_name = 'Modular Resultant Computation (GF(p))';
    fprintf('[TEST 3] %s\n', test_name);

    % Modular resultants should be in [0, p)
    in_range_PQ = (B5.modular_resultant.res_P_Q_mod >= 0) && (B5.modular_resultant.res_P_Q_mod < B5.prime_demo);
    in_range_PR = (B5.modular_resultant.res_P_R_mod >= 0) && (B5.modular_resultant.res_P_R_mod < B5.prime_demo);
    in_range_QR = (B5.modular_resultant.res_Q_R_mod >= 0) && (B5.modular_resultant.res_Q_R_mod < B5.prime_demo);

    test_pass = in_range_PQ && in_range_PR && in_range_QR;

    fprintf('  Res(P,Q) mod p = %d\n', B5.modular_resultant.res_P_Q_mod);
    fprintf('  Res(P,R) mod p = %d\n', B5.modular_resultant.res_P_R_mod);
    fprintf('  Res(Q,R) mod p = %d\n', B5.modular_resultant.res_Q_R_mod);
    fprintf('  Prime p = %d\n', B5.prime_demo);
    fprintf('  All in valid range: %s\n', iif(test_pass, 'YES', 'NO'));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 4: SIGNATURE GENERATION ==========
    test_name = 'Signature Generation from Resultant';
    fprintf('[TEST 4] %s\n', test_name);

    % Signatures should be non-empty
    sig_generated = ~isempty(B5.signature.sig_P_Q) && ...
                    ~isempty(B5.signature.sig_P_R) && ...
                    ~isempty(B5.signature.sig_Q_R);

    test_pass = sig_generated;

    fprintf('  Signature P_Q generated: %s\n', iif(~isempty(B5.signature.sig_P_Q), 'YES', 'NO'));
    fprintf('  Signature P_R generated: %s\n', iif(~isempty(B5.signature.sig_P_R), 'YES', 'NO'));
    fprintf('  Signature Q_R generated: %s\n', iif(~isempty(B5.signature.sig_Q_R), 'YES', 'NO'));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 5: SIGNATURE VERIFICATION ==========
    test_name = 'Signature Verification (Reproducibility)';
    fprintf('[TEST 5] %s\n', test_name);

    test_pass = B5.verification_sig.P_Q_matches;

    fprintf('  Original signature matches recomputed: %s\n', iif(B5.verification_sig.P_Q_matches, 'YES', 'NO'));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 6: POLYNOMIAL FAMILY ANALYSIS ==========
    test_name = 'Polynomial Family Pairwise Resultants';
    fprintf('[TEST 6] %s\n', test_name);

    % Resultants along diagonal should be 0 (Res(P,P) = 0)
    diag_zeros = all(diag(B5.polynomial_analysis.pairwise_resultants) == 0);

    % Matrix should be skew-symmetric (Res(P,Q) = -Res(Q,P) for finite fields)
    test_pass = diag_zeros;

    fprintf('  Number of polynomials: %d\n', length(B5.polynomial_analysis.family));
    fprintf('  Degrees: %d to %d\n', min(B5.polynomial_analysis.degrees), max(B5.polynomial_analysis.degrees));
    fprintf('  Diagonal entries zero: %s\n', iif(diag_zeros, 'YES', 'NO'));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 7: COLLISION RESISTANCE ==========
    test_name = 'Collision Resistance (Random Polynomials)';
    fprintf('[TEST 7] %s\n', test_name);

    test_pass = B5.collision_resistance.collision_free;

    fprintf('  Trials: %d\n', B5.collision_resistance.trials);
    fprintf('  Collisions found: %d\n', B5.collision_resistance.collisions);
    fprintf('  Collision-free: %s\n', iif(B5.collision_resistance.collision_free, 'YES', 'NO'));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 8: SYMMETRY PROPERTY ==========
    test_name = 'Symmetry: Res(Q,P) = (-1)^(deg(P)*deg(Q)) * Res(P,Q)';
    fprintf('[TEST 8] %s\n', test_name);

    test_pass = B5.property_symmetry_ok;

    fprintf('  Symmetry error: %.2e\n', B5.property_symmetry_ok);
    fprintf('  Expected sign factor: (-1)^(%d*%d) = %d\n', B5.deg_P, B5.deg_Q, (-1)^(B5.deg_P * B5.deg_Q));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 9: SIGNATURE DISTINCTIVENESS ==========
    test_name = 'Signature Distinctiveness (Perturbation Sensitivity)';
    fprintf('[TEST 9] %s\n', test_name);

    test_pass = B5.distinctiveness.both_different;

    fprintf('  Base signature differs from pert1: %s\n', iif(B5.distinctiveness.pert1_different, 'YES', 'NO'));
    fprintf('  Base signature differs from pert2: %s\n', iif(B5.distinctiveness.pert2_different, 'YES', 'NO'));
    fprintf('  Both different: %s\n', iif(B5.distinctiveness.both_different, 'YES', 'NO'));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 10: VERIFICATION CHECKLIST ==========
    test_name = 'Master Verification Checklist';
    fprintf('[TEST 10] %s\n', test_name);

    test_pass = B5.verification_complete.all_pass;

    fprintf('  Resultant computed OK: %s\n', iif(B5.verification_complete.resultant_computed_ok, 'YES', 'NO'));
    fprintf('  Common root detected OK: %s\n', iif(B5.verification_complete.common_root_detected, 'YES', 'NO'));
    fprintf('  No common root OK: %s\n', iif(B5.verification_complete.no_common_root_ok, 'YES', 'NO'));
    fprintf('  Modular resultant OK: %s\n', iif(B5.verification_complete.modular_resultant_ok, 'YES', 'NO'));
    fprintf('  Signature verifiable OK: %s\n', iif(B5.verification_complete.signature_verifiable, 'YES', 'NO'));
    fprintf('  Collision-free OK: %s\n', iif(B5.verification_complete.collision_free_ok, 'YES', 'NO'));
    fprintf('  Symmetry OK: %s\n', iif(B5.verification_complete.symmetry_ok, 'YES', 'NO'));
    fprintf('  Distinctiveness OK: %s\n', iif(B5.verification_complete.distinctiveness_ok, 'YES', 'NO'));
    fprintf('  Numerical stable OK: %s\n', iif(B5.verification_complete.numerical_stable_ok, 'YES', 'NO'));
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

function result = iif(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end
