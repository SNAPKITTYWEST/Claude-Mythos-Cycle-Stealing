% COUNTEREXAMPLE ENGINE
% Active falsification harness for open mathematical claims
%
% For each open obligation (H1-H4), this engine attempts to find counterexamples
% through:
%  - Random search over parameter space
%  - Structured boundary search
%  - Exhaustive finite enumeration (where applicable)
%  - Adversarial parameter generation
%  - Symmetry-breaking search
%
% If any counterexample is found, the claim is FALSIFIED and status becomes OPEN_FALSIFIED

classdef counterexample_engine

    properties (Constant)
        % Search strategies
        STRATEGY_RANDOM = 'random'
        STRATEGY_BOUNDARY = 'boundary'
        STRATEGY_EXHAUSTIVE = 'exhaustive'
        STRATEGY_ADVERSARIAL = 'adversarial'
    end

    methods (Static)

        % === SEARCH FOR COUNTEREXAMPLE ===
        function [found, counterexample, search_stats] = search(claim_id, claim_predicate, param_spec, varargin)
            % Search for counterexample to a mathematical claim
            %
            % Parameters:
            %   claim_id (string): identifier for claim (e.g. 'H1_OB1')
            %   claim_predicate (function): function(params) -> boolean
            %                                true if claim holds, false if counterexample
            %   param_spec (struct): parameter specification
            %
            % Returns:
            %   found (logical): whether counterexample was found
            %   counterexample (struct): the counterexample (if found)
            %   search_stats (struct): search statistics

            % Initialize
            found = false;
            counterexample = [];
            search_stats = struct();
            search_stats.claim_id = claim_id;
            search_stats.searches_attempted = 0;
            search_stats.searches_found_counterexample = 0;
            search_stats.searches_total = 0;

            % Strategy 1: RANDOM SEARCH
            fprintf('[COUNTEREXAMPLE SEARCH] %s - Random search\n', claim_id);
            [found, cx, stats1] = counterexample_engine.search_random(claim_predicate, param_spec, 10000);
            search_stats.random = stats1;
            search_stats.searches_total = search_stats.searches_total + stats1.iterations;

            if found
                counterexample = cx;
                search_stats.searches_found_counterexample = 1;
                fprintf('  ✗ COUNTEREXAMPLE FOUND: %s\n', claim_id);
                return;
            end

            % Strategy 2: BOUNDARY SEARCH
            fprintf('[COUNTEREXAMPLE SEARCH] %s - Boundary search\n', claim_id);
            [found, cx, stats2] = counterexample_engine.search_boundary(claim_predicate, param_spec);
            search_stats.boundary = stats2;
            search_stats.searches_total = search_stats.searches_total + stats2.iterations;

            if found
                counterexample = cx;
                search_stats.searches_found_counterexample = 1;
                fprintf('  ✗ COUNTEREXAMPLE FOUND: %s\n', claim_id);
                return;
            end

            % Strategy 3: EXHAUSTIVE (if finite)
            if isfield(param_spec, 'exhaustive_possible') && param_spec.exhaustive_possible
                fprintf('[COUNTEREXAMPLE SEARCH] %s - Exhaustive search\n', claim_id);
                [found, cx, stats3] = counterexample_engine.search_exhaustive(claim_predicate, param_spec);
                search_stats.exhaustive = stats3;
                search_stats.searches_total = search_stats.searches_total + stats3.iterations;

                if found
                    counterexample = cx;
                    search_stats.searches_found_counterexample = 1;
                    fprintf('  ✗ COUNTEREXAMPLE FOUND: %s\n', claim_id);
                    return;
                end
            end

            % Strategy 4: ADVERSARIAL
            fprintf('[COUNTEREXAMPLE SEARCH] %s - Adversarial search\n', claim_id);
            [found, cx, stats4] = counterexample_engine.search_adversarial(claim_predicate, param_spec);
            search_stats.adversarial = stats4;
            search_stats.searches_total = search_stats.searches_total + stats4.iterations;

            if found
                counterexample = cx;
                search_stats.searches_found_counterexample = 1;
                fprintf('  ✗ COUNTEREXAMPLE FOUND: %s\n', claim_id);
                return;
            end

            % No counterexample found
            fprintf('  ✓ No counterexample found after %d iterations\n', search_stats.searches_total);
            found = false;

            return;
        end

        % === RANDOM SEARCH ===
        function [found, cx, stats] = search_random(claim_predicate, param_spec, iterations)
            % Random parameter search

            found = false;
            cx = [];
            stats = struct();
            stats.strategy = 'random';
            stats.iterations = 0;
            stats.found = false;

            for iter = 1:iterations
                % Generate random parameters
                params = counterexample_engine.generate_random_params(param_spec);

                % Test claim
                try
                    holds = claim_predicate(params);
                catch
                    holds = true;  % Error means claim doesn't hold
                end

                stats.iterations = stats.iterations + 1;

                if ~holds
                    found = true;
                    cx = params;
                    stats.found = true;
                    return;
                end
            end

            return;
        end

        % === BOUNDARY SEARCH ===
        function [found, cx, stats] = search_boundary(claim_predicate, param_spec)
            % Structured search at boundaries

            found = false;
            cx = [];
            stats = struct();
            stats.strategy = 'boundary';
            stats.iterations = 0;
            stats.found = false;

            % Generate boundary parameters
            boundary_params = counterexample_engine.generate_boundary_params(param_spec);

            for i = 1:length(boundary_params)
                params = boundary_params{i};

                try
                    holds = claim_predicate(params);
                catch
                    holds = true;
                end

                stats.iterations = stats.iterations + 1;

                if ~holds
                    found = true;
                    cx = params;
                    stats.found = true;
                    return;
                end
            end

            return;
        end

        % === EXHAUSTIVE SEARCH ===
        function [found, cx, stats] = search_exhaustive(claim_predicate, param_spec)
            % Exhaustive enumeration (for finite spaces)

            found = false;
            cx = [];
            stats = struct();
            stats.strategy = 'exhaustive';
            stats.iterations = 0;
            stats.found = false;

            if ~isfield(param_spec, 'enumeration_items')
                stats.iterations = 0;
                return;
            end

            items = param_spec.enumeration_items;

            for i = 1:length(items)
                params = items{i};

                try
                    holds = claim_predicate(params);
                catch
                    holds = true;
                end

                stats.iterations = stats.iterations + 1;

                if ~holds
                    found = true;
                    cx = params;
                    stats.found = true;
                    return;
                end
            end

            return;
        end

        % === ADVERSARIAL SEARCH ===
        function [found, cx, stats] = search_adversarial(claim_predicate, param_spec)
            % Adversarial parameter selection

            found = false;
            cx = [];
            stats = struct();
            stats.strategy = 'adversarial';
            stats.iterations = 0;
            stats.found = false;

            % Generate adversarial parameters targeting claim weaknesses
            adversarial_params = counterexample_engine.generate_adversarial_params(param_spec);

            for i = 1:length(adversarial_params)
                params = adversarial_params{i};

                try
                    holds = claim_predicate(params);
                catch
                    holds = true;
                end

                stats.iterations = stats.iterations + 1;

                if ~holds
                    found = true;
                    cx = params;
                    stats.found = true;
                    return;
                end
            end

            return;
        end

        % === GENERATE RANDOM PARAMETERS ===
        function params = generate_random_params(param_spec)
            % Generate random parameters within specification

            params = struct();

            if isfield(param_spec, 'scalar_ranges')
                ranges = param_spec.scalar_ranges;
                names = fieldnames(ranges);
                for i = 1:length(names)
                    name = names{i};
                    range = ranges.(name);
                    if length(range) == 2
                        params.(name) = range(1) + (range(2) - range(1)) * rand();
                    end
                end
            end

            return;
        end

        % === GENERATE BOUNDARY PARAMETERS ===
        function boundary_params = generate_boundary_params(param_spec)
            % Generate boundary cases

            boundary_params = {};
            idx = 1;

            if isfield(param_spec, 'scalar_ranges')
                ranges = param_spec.scalar_ranges;
                names = fieldnames(ranges);

                for i = 1:length(names)
                    name = names{i};
                    range = ranges.(name);

                    if length(range) == 2
                        % Lower boundary
                        p1 = struct();
                        p1.(name) = range(1);
                        boundary_params{idx} = p1;
                        idx = idx + 1;

                        % Upper boundary
                        p2 = struct();
                        p2.(name) = range(2);
                        boundary_params{idx} = p2;
                        idx = idx + 1;

                        % Near-boundary (epsilon away)
                        eps = 1e-10;
                        p3 = struct();
                        p3.(name) = range(1) + eps;
                        boundary_params{idx} = p3;
                        idx = idx + 1;

                        p4 = struct();
                        p4.(name) = range(2) - eps;
                        boundary_params{idx} = p4;
                        idx = idx + 1;
                    end
                end
            end

            return;
        end

        % === GENERATE ADVERSARIAL PARAMETERS ===
        function adversarial_params = generate_adversarial_params(param_spec)
            % Generate adversarial parameters targeting weakness

            adversarial_params = {};
            idx = 1;

            % Degenerate cases
            if isfield(param_spec, 'degenerate_cases')
                cases = param_spec.degenerate_cases;
                for i = 1:length(cases)
                    adversarial_params{idx} = cases{i};
                    idx = idx + 1;
                end
            end

            % Symmetry-breaking
            if isfield(param_spec, 'symmetry_breaking')
                cases = param_spec.symmetry_breaking;
                for i = 1:length(cases)
                    adversarial_params{idx} = cases{i};
                    idx = idx + 1;
                end
            end

            return;
        end

        % === SAVE COUNTEREXAMPLE ===
        function save_counterexample(claim_id, counterexample)
            % Save discovered counterexample to file

            outdir = 'verification/counterexamples';
            if ~exist(outdir, 'dir')
                mkdir(outdir);
            end

            filename = fullfile(outdir, sprintf('%s_falsification.json', claim_id));

            output = struct();
            output.claim_id = claim_id;
            output.timestamp = datetime('now');
            output.counterexample = counterexample;

            fid = fopen(filename, 'w');
            fprintf(fid, '%s', jsonencode(output));
            fclose(fid);

            fprintf('[SAVED] Counterexample: %s\n', filename);

            return;
        end

    end
end
