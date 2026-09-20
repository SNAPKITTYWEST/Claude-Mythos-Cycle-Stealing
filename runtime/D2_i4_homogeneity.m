function result = D2_i4_homogeneity(varargin)
    % I4 Homogeneity: I4(r*z) = r^4 * I4(z)
    scaling_factors = [0.5, 0.9, 1.0, 1.1, 2.0, 10.0];
    errors = [];
    
    z_test = randn(1, 8);
    i4_z = sum(z_test.^4);
    
    for r = scaling_factors
        z_scaled = r * z_test;
        i4_rz = sum(z_scaled.^4);
        expected = (r^4) * i4_z;
        error_val = abs(i4_rz - expected) / (abs(expected) + eps);
        errors = [errors; error_val];
    end
    
    result.scaling_factors = scaling_factors;
    result.homogeneity_errors = errors;
    result.max_relative_error = max(errors);
    result.mean_relative_error = mean(errors);
    result.homogeneity_verified = max(errors) < 1e-10;
    result.status = 'CLAIMED';
end
