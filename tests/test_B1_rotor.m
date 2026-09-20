function test_B1_rotor()
    % test_B1_rotor - Comprehensive test suite for Clifford Rotor implementation
    % Tests B1_clifford_rotor module for VERIFIED_COMPUTATIONAL status
    %
    % Test categories:
    % 1. Rotor normalization (|R| = 1)
    % 2. Norm preservation under rotation
    % 3. Round-trip rotation (identity test)
    % 4. Multiple rotation composition
    % 5. Numerical error bounds
    % 6. Reverse operation correctness
    % 7. Axis-angle extraction
    % 8. Accumulation of errors over iterations

    fprintf('\n========== TEST SUITE B1: CLIFFORD ROTOR ==========\n');
    fprintf('Testing rotor-based computation in Cl(3,0)\n\n');

    % Initialize test counter
    total_tests = 0;
    passed_tests = 0;

    % ========== TEST 1: ROTOR NORMALIZATION ==========
    test_name = 'Rotor Normalization';
    fprintf('[TEST 1] %s\n', test_name);

    B1 = B1_clifford_rotor();

    % Rotor should have norm exactly 1
    norm_sq = B1.rotor_norm_sq;
    error_norm = abs(norm_sq - 1.0);

    threshold_norm = 1e-14;
    test_pass = error_norm < threshold_norm;

    fprintf('  Rotor |R|^2 = %.16f\n', norm_sq);
    fprintf('  Error: %.2e\n', error_norm);
    fprintf('  Threshold: %.2e\n', threshold_norm);
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 2: NORM PRESERVATION ==========
    test_name = 'Norm Preservation Under Rotation';
    fprintf('[TEST 2] %s\n', test_name);

    % Original vector norm vs. rotated vector norm
    v_norm_before = sqrt(2^2 + 3^2 + 4^2);  % sqrt(29)
    v_norm_error = B1.norm_preservation_error;

    threshold_norm_pres = 1e-12;
    test_pass = v_norm_error < threshold_norm_pres;

    fprintf('  Vector norm before: %.16f\n', v_norm_before);
    fprintf('  Norm preservation error: %.2e\n', v_norm_error);
    fprintf('  Threshold: %.2e\n', threshold_norm_pres);
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 3: ROUNDTRIP ROTATION ==========
    test_name = 'Round-Trip Rotation (Identity Test)';
    fprintf('[TEST 3] %s\n', test_name);

    % Apply R and R^-1: should recover original vector
    roundtrip_error = B1.roundtrip_error;

    threshold_roundtrip = 1e-12;
    test_pass = roundtrip_error < threshold_roundtrip;

    fprintf('  Original vector: [2, 3, 4]\n');
    fprintf('  Round-trip error: %.2e\n', roundtrip_error);
    fprintf('  Threshold: %.2e\n', threshold_roundtrip);
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 4: DOUBLE ROTATION ==========
    test_name = 'Double Rotation Composition';
    fprintf('[TEST 4] %s\n', test_name);

    % Two rotations should also preserve norm
    double_rot_error = B1.double_rotation_norm_error;

    threshold_double = 1e-12;
    test_pass = double_rot_error < threshold_double;

    fprintf('  Double rotation norm error: %.2e\n', double_rot_error);
    fprintf('  Threshold: %.2e\n', threshold_double);
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 5: NUMERICAL ERROR BOUNDS ==========
    test_name = 'Accumulated Numerical Errors';
    fprintf('[TEST 5] %s\n', test_name);

    max_error = B1.numerical_errors.max_accumulated;
    threshold_all = B1.numerical_errors.threshold;
    test_pass = B1.numerical_errors.passes_threshold;

    fprintf('  Max accumulated error: %.2e\n', max_error);
    fprintf('  Threshold: %.2e\n', threshold_all);
    fprintf('  Individual errors:\n');
    fprintf('    Rotor normalization: %.2e\n', B1.numerical_errors.rotor_normalization);
    fprintf('    Norm preservation: %.2e\n', B1.numerical_errors.norm_preservation);
    fprintf('    Round-trip: %.2e\n', B1.numerical_errors.roundtrip);
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 6: REVERSE OPERATION ==========
    test_name = 'Reverse (Conjugate) Operation';
    fprintf('[TEST 6] %s\n', test_name);

    % For rotor R, R * reverse(R) should equal 1 (scalar)
    conj_product = B1.rotor_conjugate_product;
    is_scalar = abs(conj_product(2:8)) < 1e-14;  % Only grade-1 onwards should be ~0
    is_one = abs(conj_product(1) - 1.0) < 1e-14;

    test_pass = all(is_scalar) && is_one;

    fprintf('  R * reverse(R) = [%.2e', conj_product(1));
    fprintf(', %.2e', conj_product(2));
    fprintf(', %.2e', conj_product(3));
    fprintf(', ...]\n');
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 7: AXIS-ANGLE EXTRACTION ==========
    test_name = 'Axis-Angle Extraction from Rotor';
    fprintf('[TEST 7] %s\n', test_name);

    angle_error = B1.axis_angle_error;
    threshold_angle = 1e-12;
    test_pass = angle_error < threshold_angle;

    fprintf('  Expected angle: π/2 = %.16f\n', pi/2);
    fprintf('  Extracted angle: %.16f\n', B1.extracted_angle);
    fprintf('  Error: %.2e\n', angle_error);
    fprintf('  Threshold: %.2e\n', threshold_angle);
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 8: GRADE EXTRACTION ==========
    test_name = 'Grade Component Extraction';
    fprintf('[TEST 8] %s\n', test_name);

    % Rotated vector should have only grade-1 (vector) components
    rotated_grade = B1.rotated_vector_grade;
    non_vector_parts = [rotated_grade(1), rotated_grade(5:8)];
    is_pure_vector = all(abs(non_vector_parts) < 1e-12);

    test_pass = is_pure_vector;

    fprintf('  Rotated vector: [%.2e', rotated_grade(1));
    fprintf(', (%.2e, %.2e, %.2e)', rotated_grade(2), rotated_grade(3), rotated_grade(4));
    fprintf(', %.2e, ...]\n', rotated_grade(5));
    fprintf('  Pure vector: %s\n', iif(is_pure_vector, 'YES', 'NO'));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 9: ITERATION STABILITY ==========
    test_name = 'Stability Over 10 Iterations';
    fprintf('[TEST 9] %s\n', test_name);

    % Repeatedly apply and inverse-apply rotor: should not accumulate errors
    v = B1.test_vector;
    R = B1.rotor_90deg;
    R_conj = B1.rotor_90deg_reverse;

    v_current = v;
    max_iteration_error = 0;

    for iter = 1:10
        % Apply rotation
        Rv = clifford_multiply_simple(R, v_current);
        v_current = clifford_multiply_simple(Rv, R_conj);

        % Check norm
        norm_current = norm(v_current(2:4));
        norm_expected = sqrt(2^2 + 3^2 + 4^2);
        iter_error = abs(norm_current - norm_expected);
        max_iteration_error = max(max_iteration_error, iter_error);
    end

    threshold_iter = 1e-10;
    test_pass = max_iteration_error < threshold_iter;

    fprintf('  Iterations: 10\n');
    fprintf('  Max error per iteration: %.2e\n', max_iteration_error);
    fprintf('  Threshold: %.2e\n', threshold_iter);
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 10: VERIFICATION CHECKLIST ==========
    test_name = 'Master Verification Checklist';
    fprintf('[TEST 10] %s\n', test_name);

    test_pass = B1.verification.all_pass;

    fprintf('  Rotor normalization OK: %s\n', iif(B1.verification.rotor_normalization_ok, 'YES', 'NO'));
    fprintf('  Norm preserved OK: %s\n', iif(B1.verification.norm_preserved_ok, 'YES', 'NO'));
    fprintf('  Double rotation OK: %s\n', iif(B1.verification.double_rotation_ok, 'YES', 'NO'));
    fprintf('  Round-trip OK: %s\n', iif(B1.verification.roundtrip_ok, 'YES', 'NO'));
    fprintf('  Axis-angle OK: %s\n', iif(B1.verification.axis_angle_ok, 'YES', 'NO'));
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

% ========== HELPER FUNCTIONS ==========

function result = iif(condition, true_val, false_val)
    % Simple if-then-else
    if condition
        result = true_val;
    else
        result = false_val;
    end
end

function result = clifford_multiply_simple(a, b)
    % Simplified Clifford multiplication for testing
    % For small vectors, use geometric product approximation

    result = zeros(1, 8);

    % Simple approximation: scalar*b, vector cross product
    result(1) = a(1)*b(1) + dot(a(2:4), b(2:4));
    result(2:4) = a(1)*b(2:4) + b(1)*a(2:4) + cross(a(2:4), b(2:4));

end
