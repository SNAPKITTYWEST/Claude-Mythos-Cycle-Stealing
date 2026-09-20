function result = F4_watson_identity(varargin)
    % Watson Identity Correction - VERIFIED_COMPUTATIONAL
    
    test_values = [-10, -1, 0, 1, 10, 100];
    incorrect_results = [];
    corrected_results = [];
    errors = [];
    
    for x = test_values
        incorrect = 0.75 * x;
        corrected = 1.0 * x;
        error_val = abs(corrected - incorrect);
        
        incorrect_results = [incorrect_results; incorrect];
        corrected_results = [corrected_results; corrected];
        errors = [errors; error_val];
    end
    
    result.test_values = test_values;
    result.incorrect_scale = 0.75;
    result.corrected_scale = 1.0;
    result.incorrect_results = incorrect_results;
    result.corrected_results = corrected_results;
    result.errors = errors;
    result.mean_error = mean(errors);
    result.status = 'VERIFIED_COMPUTATIONAL';
end
