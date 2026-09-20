function test_B3_hamiltonian()
    % test_B3_hamiltonian - Test suite for Hamiltonian Schedule Evolution
    % Tests B3_hamiltonian_evolution module for CLAIMED status
    %
    % Test categories:
    % 1. Bivector basis setup (skew-hermitian)
    % 2. Hamiltonian construction
    % 3. Unitarity verification
    % 4. Norm preservation
    % 5. Spectral stability
    % 6. Commutation relations
    % 7. Periodicity
    % 8. Energy conservation

    fprintf('\n========== TEST SUITE B3: HAMILTONIAN EVOLUTION ==========\n');
    fprintf('Testing Hamiltonian schedule evolution with rotor trajectory\n\n');

    total_tests = 0;
    passed_tests = 0;

    % ========== TEST 1: BIVECTOR BASIS SKEW-HERMITIAN ==========
    test_name = 'Bivector Basis Skew-Hermitian Property';
    fprintf('[TEST 1] %s\n', test_name);

    B3 = B3_hamiltonian_evolution();

    % For skew-hermitian: B + B† = 0
    threshold = 1e-14;
    test_pass = (B3.bivector_verify.B1_skew < threshold) && ...
                (B3.bivector_verify.B2_skew < threshold) && ...
                (B3.bivector_verify.B3_skew < threshold);

    fprintf('  B1 skew-hermitian error: %.2e\n', B3.bivector_verify.B1_skew);
    fprintf('  B2 skew-hermitian error: %.2e\n', B3.bivector_verify.B2_skew);
    fprintf('  B3 skew-hermitian error: %.2e\n', B3.bivector_verify.B3_skew);
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 2: HAMILTONIAN CONSTRUCTION ==========
    test_name = 'Hamiltonian Construction';
    fprintf('[TEST 2] %s\n', test_name);

    % Hamiltonians should be 3x3 skew-hermitian
    threshold = 1e-14;
    test_pass = (B3.hamiltonian_verify.H1_skew < threshold) && ...
                (B3.hamiltonian_verify.H2_skew < threshold) && ...
                (B3.hamiltonian_verify.H3_skew < threshold);

    fprintf('  H1 skew-hermitian error: %.2e\n', B3.hamiltonian_verify.H1_skew);
    fprintf('  H2 skew-hermitian error: %.2e\n', B3.hamiltonian_verify.H2_skew);
    fprintf('  H3 skew-hermitian error: %.2e\n', B3.hamiltonian_verify.H3_skew);
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 3: UNITARITY VERIFICATION ==========
    test_name = 'Unitarity: U(t)*U(t)† = I';
    fprintf('[TEST 3] %s\n', test_name);

    test_pass = B3.unitarity_check.passes;

    fprintf('  Max unitarity error (H1): %.2e\n', B3.unitarity_check.max_error_H1);
    fprintf('  Mean unitarity error (H1): %.2e\n', B3.unitarity_check.mean_error_H1);
    fprintf('  Max unitarity error (H2): %.2e\n', B3.unitarity_check.max_error_H2);
    fprintf('  Threshold: %.2e\n', B3.unitarity_check.threshold);
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 4: NORM PRESERVATION ==========
    test_name = 'Norm Preservation: |U(t)*ψ| = |ψ|';
    fprintf('[TEST 4] %s\n', test_name);

    test_pass = B3.norm_preservation.passes;

    fprintf('  Max norm preservation error: %.2e\n', B3.norm_preservation.max_error);
    fprintf('  Threshold: %.2e\n', B3.norm_preservation.threshold);
    fprintf('  Test vectors: 3 (pure, mixed, complex)\n');
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 5: SPECTRAL STABILITY ==========
    test_name = 'Spectral Stability (Eigenvalues on Unit Circle)';
    fprintf('[TEST 5] %s\n', test_name);

    test_pass = B3.spectral_stability.passes;

    fprintf('  Spectral radius error (H1): %.2e\n', B3.spectral_stability.spectral_radius_unit_H1);
    fprintf('  Spectral radius error (H2): %.2e\n', B3.spectral_stability.spectral_radius_unit_H2);
    fprintf('  Threshold: %.2e\n', B3.spectral_stability.threshold);
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 6: COMMUTATION RELATIONS ==========
    test_name = 'Commutation Relations: [Bi, Bj]';
    fprintf('[TEST 6] %s\n', test_name);

    test_pass = B3.commutation_relations.passes;

    fprintf('  [B1, B2] error: %.2e (expect 2*B3)\n', B3.commutation_relations.B1_B2_error);
    fprintf('  [B2, B3] error: %.2e (expect 2*B1)\n', B3.commutation_relations.B2_B3_error);
    fprintf('  [B3, B1] error: %.2e (expect 2*B2)\n', B3.commutation_relations.B3_B1_error);
    fprintf('  Threshold: %.2e\n', B3.commutation_relations.threshold);
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 7: PERIODICITY ==========
    test_name = 'Periodicity: U(2π) ≈ I';
    fprintf('[TEST 7] %s\n', test_name);

    test_pass = B3.periodicity.passes;

    fprintf('  Error at t=2π: %.2e\n', B3.periodicity.error_at_2pi);
    fprintf('  Threshold: %.2e\n', B3.periodicity.threshold);
    fprintf('  Period: 2π\n');
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 8: ENERGY CONSERVATION ==========
    test_name = 'Energy Conservation: <ψ|H|ψ> = const';
    fprintf('[TEST 8] %s\n', test_name);

    test_pass = B3.energy_conservation.passes;

    fprintf('  Initial energy: %.16f\n', B3.energy_conservation.initial_energy);
    fprintf('  Max energy variation: %.2e\n', B3.energy_conservation.max_error);
    fprintf('  Threshold: %.2e\n', B3.energy_conservation.threshold);
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 9: ROTOR TRAJECTORY PROPERTIES ==========
    test_name = 'Rotor Trajectory Norm Conservation';
    fprintf('[TEST 9] %s\n', test_name);

    max_norm_change = B3.rotor_trajectory.max_norm_change;
    threshold_norm = 1e-12;
    test_pass = max_norm_change < threshold_norm;

    fprintf('  Initial rotor Frobenius norm: %.2e\n', norm(B3.rotor_trajectory.H1{1}, 'fro'));
    fprintf('  Max norm change: %.2e\n', max_norm_change);
    fprintf('  Threshold: %.2e\n', threshold_norm);
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 10: VERIFICATION CHECKLIST ==========
    test_name = 'Master Verification Checklist';
    fprintf('[TEST 10] %s\n', test_name);

    test_pass = B3.verification.all_pass;

    fprintf('  Hamiltonian structure OK: %s\n', iif(B3.verification.hamiltonian_skew_hermitian_ok, 'YES', 'NO'));
    fprintf('  Unitarity OK: %s\n', iif(B3.verification.unitarity_ok, 'YES', 'NO'));
    fprintf('  Norm preservation OK: %s\n', iif(B3.verification.norm_preservation_ok, 'YES', 'NO'));
    fprintf('  Spectral stability OK: %s\n', iif(B3.verification.spectral_stability_ok, 'YES', 'NO'));
    fprintf('  Commutation relations OK: %s\n', iif(B3.verification.commutation_relations_ok, 'YES', 'NO'));
    fprintf('  Periodicity OK: %s\n', iif(B3.verification.periodicity_ok, 'YES', 'NO'));
    fprintf('  Energy conservation OK: %s\n', iif(B3.verification.energy_conservation_ok, 'YES', 'NO'));
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
