% RUNTIME INSTRUMENTATION API
% Provides consistent observability and telemetry across all novel finding runtimes
%
% Usage:
%   runtime = runtime_begin('A1_cycle_stealing_moe', struct('cycles_max', 2000));
%   runtime = runtime_event(runtime, 'dma_dispatch', struct('channel', 3, 'cost', 250));
%   runtime = runtime_metric(runtime, 'bus_overlap', 0.45);
%   runtime = runtime_assert(runtime, 'cycle_conservation', true, 'Cycles must conserve');
%   result = runtime_end(runtime);

classdef runtime_instrumentation_api
    methods (Static)

        % === BEGIN RUNTIME ===
        function rt = begin(finding_id, parameters)
            % Initialize a runtime session for a finding
            %
            % Parameters:
            %   finding_id (string): unique finding identifier (e.g. 'A1', 'B3', 'H2')
            %   parameters (struct): optional problem parameters
            %
            % Returns:
            %   rt (struct): runtime context with instrumentation

            rt = struct();
            rt.finding_id = finding_id;
            rt.run_id = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss_SSS')) + "_" + string(randi(10000));
            rt.timestamp_start = datetime('now');
            rt.timestamp_ticks_start = tic();

            % Parameters
            rt.parameters = parameters;

            % Event log
            rt.events = [];
            rt.event_count = 0;
            rt.event_max = 100000;

            % Metrics
            rt.metrics = struct();
            rt.metric_names = {};
            rt.metric_values = [];
            rt.metric_timestamps = [];

            % Invariant checks
            rt.invariants = struct();
            rt.invariant_count = 0;
            rt.invariant_pass = 0;
            rt.invariant_fail = 0;

            % Status
            rt.status = 'INITIALIZED';
            rt.error_message = '';
            rt.warning_count = 0;

            % Results
            rt.result = [];

            return;
        end

        % === LOG EVENT ===
        function rt = event(rt, event_type, event_data)
            % Log a named event with optional data

            if rt.event_count >= rt.event_max
                rt.status = 'EVENT_LOG_FULL';
                return;
            end

            evt = struct();
            evt.event_id = rt.event_count + 1;
            evt.type = event_type;
            evt.timestamp = datetime('now');
            evt.timestamp_tick = toc(rt.timestamp_ticks_start);
            evt.data = event_data;

            if isempty(rt.events)
                rt.events = evt;
            else
                rt.events(end+1) = evt;
            end

            rt.event_count = rt.event_count + 1;

            return;
        end

        % === RECORD METRIC ===
        function rt = metric(rt, metric_name, metric_value)
            % Record a named metric value

            if ~isfield(rt.metrics, metric_name)
                rt.metrics.(metric_name) = [];
                rt.metric_names{end+1} = metric_name;
            end

            rt.metric_values = [rt.metric_values; metric_value];
            rt.metric_timestamps = [rt.metric_timestamps; toc(rt.timestamp_ticks_start)];

            rt.metrics.(metric_name) = [rt.metrics.(metric_name); metric_value];

            return;
        end

        % === ASSERT INVARIANT ===
        function rt = assert(rt, invariant_name, condition, message)
            % Check an invariant, log result

            rt.invariant_count = rt.invariant_count + 1;

            inv = struct();
            inv.invariant_id = rt.invariant_count;
            inv.name = invariant_name;
            inv.condition = condition;
            inv.message = message;
            inv.timestamp = datetime('now');
            inv.tick = toc(rt.timestamp_ticks_start);

            if condition
                inv.status = 'PASS';
                rt.invariant_pass = rt.invariant_pass + 1;
            else
                inv.status = 'FAIL';
                rt.invariant_fail = rt.invariant_fail + 1;
                rt.status = 'INVARIANT_VIOLATED';
                rt.error_message = sprintf('Invariant %s failed: %s', invariant_name, message);
            end

            if isempty(rt.invariants)
                rt.invariants = inv;
            else
                rt.invariants(end+1) = inv;
            end

            return;
        end

        % === END RUNTIME ===
        function rt = end_runtime(rt)
            % Finalize runtime session and compute summary

            rt.timestamp_end = datetime('now');
            rt.elapsed_seconds = toc(rt.timestamp_ticks_start);
            rt.status = 'COMPLETED';

            % Compute summary
            rt.summary = struct();
            rt.summary.finding_id = rt.finding_id;
            rt.summary.run_id = rt.run_id;
            rt.summary.elapsed_seconds = rt.elapsed_seconds;
            rt.summary.event_count = rt.event_count;
            rt.summary.invariant_total = rt.invariant_count;
            rt.summary.invariant_pass = rt.invariant_pass;
            rt.summary.invariant_fail = rt.invariant_fail;
            rt.summary.invariant_pass_rate = rt.invariant_pass / max(1, rt.invariant_count);
            rt.summary.status = rt.status;
            rt.summary.error_message = rt.error_message;

            return;
        end

        % === SERIALIZE TO JSON ===
        function json_str = to_json(rt)
            % Serialize runtime context to JSON

            output = struct();
            output.finding_id = rt.finding_id;
            output.run_id = rt.run_id;
            output.timestamp_start = char(rt.timestamp_start);
            output.timestamp_end = char(rt.timestamp_end);
            output.elapsed_seconds = rt.elapsed_seconds;
            output.event_count = rt.event_count;
            output.invariant_summary = struct(...
                'total', rt.invariant_count, ...
                'pass', rt.invariant_pass, ...
                'fail', rt.invariant_fail, ...
                'pass_rate', rt.invariant_pass / max(1, rt.invariant_count));
            output.status = rt.status;
            output.error_message = rt.error_message;
            output.parameters = rt.parameters;

            json_str = jsonencode(output);

            return;
        end

        % === SAVE TO FILE ===
        function save_file = save(rt, output_dir)
            % Save runtime telemetry to file

            if ~exist(output_dir, 'dir')
                mkdir(output_dir);
            end

            % Filename based on finding and timestamp
            save_file = fullfile(output_dir, sprintf('%s_%s.json', rt.finding_id, rt.run_id));

            fid = fopen(save_file, 'w');
            fprintf(fid, '%s', runtime_instrumentation_api.to_json(rt));
            fclose(fid);

            return;
        end

    end
end
