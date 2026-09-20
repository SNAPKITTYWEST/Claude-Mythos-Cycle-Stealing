function test_B4_commitment()
    % test_B4_commitment - Test suite for Projective Cross-Ratio Commitment
    % Tests B4_cross_ratio_commitment module for CLAIMED status
    %
    % Test categories:
    % 1. Cross-ratio computation
    % 2. Projective invariance
    % 3. Commitment scheme validity
    % 4. Binding property
    % 5. Hiding property
    % 6. Collision resistance
    % 7. Tamper resistance

    fprintf('\n========== TEST SUITE B4: CROSS-RATIO COMMITMENT ==========\n');
    fprintf('Testing projective cross-ratio as cryptographic commitment\n\n');

    total_tests = 0;
    passed_tests = 0;

    % ========== TEST 1: CROSS-RATIO COMPUTATION ==========
    test_name = 'Cross-Ratio Computation';
    fprintf('[TEST 1] %s\n', test_name);

    B4 = B4_cross_ratio_commitment();

    % Cross-ratio should be non-NaN complex number
    cr_computed = B4.cross_ratio.value_method2;
    test_pass = ~isnan(cr_computed) && isfinite(cr_computed);

    fprintf('  Cross-ratio: %.6f + %.6fi\n', real(cr_computed), imag(cr_computed));
    fprintf('  Non-NaN: %s\n', iif(~isnan(cr_computed), 'YES', 'NO'));
    fprintf('  Finite: %s\n', iif(isfinite(cr_computed), 'YES', 'NO'));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 2: PROJECTIVE INVARIANCE ==========
    test_name = 'Invariance Under Projective Transformation';
    fprintf('[TEST 2] %s\n', test_name);

    test_pass = B4.projective_invariance.invariant_ok;

    fprintf('  Original cross-ratio: %.6f + %.6fi\n', ...
        real(B4.projective_invariance.cr_original), imag(B4.projective_invariance.cr_original));
    fprintf('  Transformed cross-ratio: %.6f + %.6fi\n', ...
        real(B4.projective_invariance.cr_transformed), imag(B4.projective_invariance.cr_transformed));
    fprintf('  Invariance error: %.2e\n', B4.projective_invariance.error);
    fprintf('  Threshold: %.2e\n', B4.projective_invariance.threshold);
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 3: COMMITMENT VALIDITY ==========
    test_name = 'Commitment/Opening Consistency';
    fprintf('[TEST 3] %s\n', test_name);

    test_pass = B4.commitment_scheme.opening_valid;

    fprintf('  Commitment generated: %s\n', iif(~isempty(B4.commitment_scheme.commitment), 'YES', 'NO'));
    fprintf('  Opening verifies: %s\n', iif(B4.commitment_scheme.opening_valid, 'YES', 'NO'));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 4: BINDING PROPERTY ==========
    test_name = 'Binding: No Collisions Found';
    fprintf('[TEST 4] %s\n', test_name);

    test_pass = B4.binding_property.binding_holds;

    fprintf('  Collision attempts: %d\n', B4.binding_property.collision_attempts);
    fprintf('  Collisions found: %d\n', B4.binding_property.collisions_found);
    fprintf('  Collision rate: %.4f%%\n', 100 * B4.binding_property.collision_rate);
    fprintf('  Binding holds: %s\n', iif(B4.binding_property.binding_holds, 'YES', 'NO'));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 5: HIDING PROPERTY ==========
    test_name = 'Hiding: High Entropy of Commitments';
    fprintf('[TEST 5] %s\n', test_name);

    test_pass = B4.hiding_property.hiding_ok;

    fprintf('  Sample size: %d\n', B4.hiding_property.samples);
    fprintf('  Entropy: %.2f bits\n', B4.hiding_property.entropy);
    fprintf('  Max entropy: %.2f bits\n', B4.hiding_property.max_entropy);
    fprintf('  Hiding property OK: %s\n', iif(B4.hiding_property.hiding_ok, 'YES', 'NO'));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 6: COLLISION RESISTANCE ==========
    test_name = 'Collision Resistance of Hash';
    fprintf('[TEST 6] %s\n', test_name);

    test_pass = B4.collision_resistance.passes;

    fprintf('  Test size: %d\n', B4.collision_resistance.test_size);
    fprintf('  Unique values: %d\n', B4.collision_resistance.unique_values);
    fprintf('  Collision count: %d\n', B4.collision_resistance.collision_count);
    fprintf('  Collision rate: %.4f%%\n', 100 * B4.collision_resistance.collision_rate);
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 7: TAMPER RESISTANCE ==========
    test_name = 'Tamper Detection (Point Modification)';
    fprintf('[TEST 7] %s\n', test_name);

    test_pass = B4.tamper_resistance.all_detect_tampering;

    fprintf('  All points tamper-detectable: %s\n', iif(B4.tamper_resistance.all_detect_tampering, 'YES', 'NO'));
    results = B4.tamper_resistance.results;
    for point_idx = 1:4
        point_name = ['P', num2str(point_idx)];
        point_result = getfield(results, point_name);
        fprintf('    %s tamper detected: %s\n', point_name, iif(point_result.hash_different, 'YES', 'NO'));
    end
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 8: AFFINE REPRESENTATION ==========
    test_name = 'Affine Point Representation';
    fprintf('[TEST 8] %s\n', test_name);

    % Check that points have valid affine coordinates
    has_valid_affine = true;
    affine_points = {'P1', 'P2', 'P3', 'P4'};

    for p = 1:length(affine_points)
        pt_name = affine_points{p};
        pt = getfield(B4.test_points_affine, pt_name);
        if ~isfinite(pt(1)) || ~isfinite(pt(2))
            has_valid_affine = false;
            break;
        end
    end

    test_pass = has_valid_affine;

    fprintf('  All affine points valid: %s\n', iif(has_valid_affine, 'YES', 'NO'));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 9: FIELD SPECIFICATION ==========
    test_name = 'Field Specification Consistency';
    fprintf('[TEST 9] %s\n', test_name);

    % Field should be well-defined prime
    field_consistent = (B4.prime_demo > 0) && (B4.field_prime > 2^255);

    test_pass = field_consistent;

    fprintf('  Demo field: p = %d\n', B4.prime_demo);
    fprintf('  Full field: p ≈ 2^256\n');
    fprintf('  Field consistency: %s\n', iif(field_consistent, 'YES', 'NO'));
    fprintf('  Result: %s\n\n', iif(test_pass, 'PASS', 'FAIL'));

    total_tests = total_tests + 1;
    passed_tests = passed_tests + iif(test_pass, 1, 0);

    % ========== TEST 10: VERIFICATION CHECKLIST ==========
    test_name = 'Master Verification Checklist';
    fprintf('[TEST 10] %s\n', test_name);

    test_pass = B4.verification.all_pass;

    fprintf('  Cross-ratio computed OK: %s\n', iif(B4.verification.cross_ratio_computed_ok, 'YES', 'NO'));
    fprintf('  Projective invariant OK: %s\n', iif(B4.verification.projective_invariant_ok, 'YES', 'NO'));
    fprintf('  Commitment valid OK: %s\n', iif(B4.verification.commitment_valid_ok, 'YES', 'NO'));
    fprintf('  Binding OK: %s\n', iif(B4.verification.binding_ok, 'YES', 'NO'));
    fprintf('  Hiding OK: %s\n', iif(B4.verification.hiding_ok, 'YES', 'NO'));
    fprintf('  Collision resistant OK: %s\n', iif(B4.verification.collision_resistant_ok, 'YES', 'NO'));
    fprintf('  Tamper resistant OK: %s\n', iif(B4.verification.tamper_resistant_ok, 'YES', 'NO'));
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
