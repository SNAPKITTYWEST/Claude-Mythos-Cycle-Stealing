% SAS BRIDGE — Independent Cross-Language Verification
% Provides MATLAB ↔ SAS bidirectional validation
%
% Usage:
%   comparison = sas_bridge.compare_computation('finite_field_ops', ...
%       struct('field_size', 256, 'test_vectors', [...]), ...
%       'verification/sas_outputs/field_ops.csv');
%
% Comparison reports:
%   - Absolute error
%   - Relative error
%   - Tolerance bounds
%   - Pass/fail status per test vector

classdef sas_bridge

    properties (Constant)
        % Default tolerances
        ABSOLUTE_TOLERANCE = 1e-12
        RELATIVE_TOLERANCE = 1e-10
        PERCENTAGE_TOLERANCE = 0.01  % 0.01% = 0.0001
    end

    methods (Static)

        % === COMPARE MATLAB VS SAS ===
        function comparison = compare_computation(test_name, matlab_result, sas_output_file, varargin)
            % Compare MATLAB computation against independent SAS implementation
            %
            % Parameters:
            %   test_name (string): name of computation being verified
            %   matlab_result (struct or array): result from MATLAB computation
            %   sas_output_file (string): path to SAS output CSV
            %
            % Returns:
            %   comparison (struct): detailed comparison report

            comparison = struct();
            comparison.test_name = test_name;
            comparison.timestamp = datetime('now');

            % Read SAS output
            if ~isfile(sas_output_file)
                comparison.status = 'ERROR_SAS_FILE_NOT_FOUND';
                comparison.sas_file = sas_output_file;
                return;
            end

            try
                sas_data = readtable(sas_output_file);
            catch
                comparison.status = 'ERROR_SAS_READ_FAILED';
                comparison.sas_file = sas_output_file;
                return;
            end

            % Initialize comparison metrics
            comparison.vector_count = size(sas_data, 1);
            comparison.vectors = [];
            comparison.absolute_errors = [];
            comparison.relative_errors = [];
            comparison.passed_count = 0;
            comparison.failed_count = 0;

            % Compare each vector
            for vec_idx = 1:size(sas_data, 1)
                sas_vec = sas_data(vec_idx, :);

                % Extract MATLAB equivalent result
                if isstruct(matlab_result)
                    matlab_vec = matlab_result;  % Single result
                else
                    matlab_vec = matlab_result(vec_idx, :);  % Array of results
                end

                % Compute differences
                vec_comparison = sas_bridge.compare_vector(matlab_vec, sas_vec);

                comparison.vectors = [comparison.vectors; vec_comparison];

                if vec_comparison.passed
                    comparison.passed_count = comparison.passed_count + 1;
                else
                    comparison.failed_count = comparison.failed_count + 1;
                end

                comparison.absolute_errors = [comparison.absolute_errors; vec_comparison.absolute_error];
                comparison.relative_errors = [comparison.relative_errors; vec_comparison.relative_error];
            end

            % Summary statistics
            comparison.absolute_error_max = max(comparison.absolute_errors);
            comparison.absolute_error_mean = mean(comparison.absolute_errors);
            comparison.relative_error_max = max(comparison.relative_errors);
            comparison.relative_error_mean = mean(comparison.relative_errors);
            comparison.pass_rate = comparison.passed_count / max(1, comparison.vector_count);

            % Overall status
            if comparison.failed_count == 0
                comparison.status = 'PASS';
            else
                comparison.status = 'FAIL';
            end

            return;
        end

        % === COMPARE SINGLE VECTOR ===
        function vec_comp = compare_vector(matlab_val, sas_val, varargin)
            % Compare single test vector

            % Parse options
            p = inputParser();
            addParameter(p, 'AbsoluteTolerance', sas_bridge.ABSOLUTE_TOLERANCE);
            addParameter(p, 'RelativeTolerance', sas_bridge.RELATIVE_TOLERANCE);
            parse(p, varargin{:});

            abs_tol = p.Results.AbsoluteTolerance;
            rel_tol = p.Results.RelativeTolerance;

            vec_comp = struct();
            vec_comp.matlab_value = matlab_val;
            vec_comp.sas_value = sas_val;

            % Compute absolute error
            if isnumeric(matlab_val) && isnumeric(sas_val)
                vec_comp.absolute_error = abs(matlab_val - sas_val);
            else
                vec_comp.absolute_error = NaN;
            end

            % Compute relative error
            if ~isnan(vec_comp.absolute_error)
                if abs(sas_val) > eps
                    vec_comp.relative_error = abs(vec_comp.absolute_error / sas_val);
                else
                    vec_comp.relative_error = NaN;
                end
            else
                vec_comp.relative_error = NaN;
            end

            % Check tolerance
            abs_pass = vec_comp.absolute_error <= abs_tol;
            rel_pass = isnan(vec_comp.relative_error) || (vec_comp.relative_error <= rel_tol);

            vec_comp.passed = abs_pass && rel_pass;
            vec_comp.absolute_tolerance = abs_tol;
            vec_comp.relative_tolerance = rel_tol;

            return;
        end

        % === GENERATE SAS CODE TEMPLATE ===
        function sas_code = generate_sas_template(computation_name, parameters)
            % Generate SAS code template for independent verification
            %
            % The returned SAS code is a DIFFERENT IMPLEMENTATION,
            % not a translation of MATLAB code

            sas_code = sprintf('''%s%s\n', ...
                '/* INDEPENDENT SAS VERIFICATION PROGRAM\n', ...
                sprintf('   Computation: %s\n', computation_name), ...
                '   Purpose: Cross-language validation\n', ...
                '   Generated by: MATLAB Cycle-Mythos Framework\n', ...
                sprintf('   Timestamp: %s\n', datetime('now')), ...
                '*/\n\n', ...
                'PROC IML;\n', ...
                '  /* Independent implementation - DO NOT TRANSLATE FROM MATLAB */\n\n', ...
                '  /* Parameters */\n', ...
                sprintf('  %s = %s;\n', parameters, '/* CONFIGURE HERE */'), ...
                '\n', ...
                '  /* Computation (independent implementation) */\n', ...
                '  result = /* YOUR IMPLEMENTATION HERE */;\n\n', ...
                '  /* Output for comparison */\n', ...
                '  CREATE work.sas_output FROM result;\n', ...
                '  APPEND FROM result;\n', ...
                '  CLOSE work.sas_output;\n\n', ...
                'QUIT;\n\n', ...
                '/* EXPORT TO CSV */\n', ...
                'PROC EXPORT DATA=work.sas_output OUTFILE=''.../output.csv'' DBMS=CSV;\n', ...
                'RUN;\n');

            return;
        end

        % === GENERATE COMPARISON REPORT ===
        function report_text = generate_report(comparison)
            % Generate human-readable comparison report

            report_text = sprintf('''%s%s\n', ...
                '═══════════════════════════════════════════════════════\n', ...
                sprintf('MATLAB ↔ SAS VERIFICATION REPORT\n'), ...
                '═══════════════════════════════════════════════════════\n\n', ...
                sprintf('Test: %s\n', comparison.test_name), ...
                sprintf('Timestamp: %s\n', comparison.timestamp), ...
                sprintf('Status: %s\n\n', comparison.status), ...
                sprintf('Vector Count: %d\n', comparison.vector_count), ...
                sprintf('Passed: %d\n', comparison.passed_count), ...
                sprintf('Failed: %d\n', comparison.failed_count), ...
                sprintf('Pass Rate: %.2f%%\n\n', 100 * comparison.pass_rate), ...
                '─ ABSOLUTE ERROR STATISTICS ─\n', ...
                sprintf('  Max: %e\n', comparison.absolute_error_max), ...
                sprintf('  Mean: %e\n', comparison.absolute_error_mean), ...
                sprintf('  Tolerance: %e\n\n', sas_bridge.ABSOLUTE_TOLERANCE), ...
                '─ RELATIVE ERROR STATISTICS ─\n', ...
                sprintf('  Max: %e\n', comparison.relative_error_max), ...
                sprintf('  Mean: %e\n', comparison.relative_error_mean), ...
                sprintf('  Tolerance: %e\n\n', sas_bridge.RELATIVE_TOLERANCE), ...
                sprintf('%s', sas_bridge.detailed_vector_report(comparison)));

            return;
        end

        % === DETAILED VECTOR REPORT ===
        function detailed = detailed_vector_report(comparison)
            % Generate detailed per-vector report

            detailed = '─ PER-VECTOR DETAILS ─\n';

            for i = 1:min(10, length(comparison.vectors))
                v = comparison.vectors(i);
                status_str = '';
                if v.passed
                    status_str = '✓ PASS';
                else
                    status_str = '✗ FAIL';
                end

                detailed = sprintf('%s\nVector %d: %s\n', detailed, i, status_str);
                detailed = sprintf('%s  MATLAB: %e\n', detailed, v.matlab_value);
                detailed = sprintf('%s  SAS:    %e\n', detailed, v.sas_value);
                detailed = sprintf('%s  Δ(abs):  %e (tol: %e)\n', detailed, v.absolute_error, v.absolute_tolerance);
                detailed = sprintf('%s  Δ(rel):  %e (tol: %e)\n', detailed, v.relative_error, v.relative_tolerance);
            end

            if length(comparison.vectors) > 10
                detailed = sprintf('%s\n... (%d more vectors)\n', detailed, length(comparison.vectors) - 10);
            end

            return;
        end

        % === SAVE COMPARISON TO FILE ===
        function filename = save_report(comparison, output_dir)
            % Save comparison report to file

            if ~exist(output_dir, 'dir')
                mkdir(output_dir);
            end

            filename = fullfile(output_dir, sprintf('%s_comparison_%s.txt', ...
                comparison.test_name, ...
                string(datetime('now', 'Format', 'yyyyMMdd_HHmmss'))));

            fid = fopen(filename, 'w');
            fprintf(fid, '%s', sas_bridge.generate_report(comparison));
            fclose(fid);

            fprintf('Saved comparison report: %s\n', filename);

            return;
        end

    end
end
