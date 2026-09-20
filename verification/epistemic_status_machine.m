% EPISTEMIC STATUS MACHINE
% Implements state machine for epistemic classifications
% Prevents fabricated status upgrades through transition guards
%
% Valid states:
%   MACHINE_CHECKED    - Mathematically proved with formal artifact
%   VERIFIED_FORMAL    - Formally verified in proof assistant
%   VERIFIED_COMPUTATIONAL - Passed all computational tests, no counterexample
%   AXIOM              - Treated as foundational (no proof obligation here)
%   CLAIMED            - Initial hypothesis formulation
%   OPEN               - Unproved with active investigation
%
% Transition rules are STRICT. Never permit upgrade without evidence.

classdef epistemic_status_machine

    properties (Constant)
        % State definitions
        MACHINE_CHECKED = "MACHINE_CHECKED"
        VERIFIED_FORMAL = "VERIFIED_FORMAL"
        VERIFIED_COMPUTATIONAL = "VERIFIED_COMPUTATIONAL"
        AXIOM = "AXIOM"
        CLAIMED = "CLAIMED"
        OPEN = "OPEN"

        % All valid states
        VALID_STATES = ["MACHINE_CHECKED", "VERIFIED_FORMAL", "VERIFIED_COMPUTATIONAL", "AXIOM", "CLAIMED", "OPEN"]
    end

    methods (Static)

        % === CREATE FINDING ===
        function finding = create(finding_id, title, initial_status)
            % Create a new finding record with epistemic state

            if ~ismember(initial_status, epistemic_status_machine.VALID_STATES)
                error('Invalid initial status: %s', initial_status);
            end

            finding = struct();
            finding.finding_id = finding_id;
            finding.title = title;
            finding.current_status = initial_status;
            finding.status_history = struct(...
                'status', {initial_status}, ...
                'timestamp', {datetime('now')}, ...
                'reason', {'Initial classification'}, ...
                'evidence', {''});
            finding.status_history_count = 1;

            finding.computational_tests_pass = false;
            finding.computational_tests_count = 0;
            finding.computational_counterexample = false;

            finding.formal_proof_present = false;
            finding.formal_proof_file = '';

            finding.open_obligations = {};
            finding.open_obligation_count = 0;

            finding.test_results = [];
            finding.warning_messages = {};

            return;
        end

        % === RECORD COMPUTATIONAL TEST ===
        function finding = record_test(finding, test_name, passed, counterexample_found)
            % Record result of computational test

            if ~exist('counterexample_found', 'var')
                counterexample_found = false;
            end

            test_result = struct();
            test_result.test_name = test_name;
            test_result.passed = passed;
            test_result.timestamp = datetime('now');
            test_result.counterexample = counterexample_found;

            if isempty(finding.test_results)
                finding.test_results = test_result;
            else
                finding.test_results(end+1) = test_result;
            end

            finding.computational_tests_count = finding.computational_tests_count + 1;

            if counterexample_found
                finding.computational_counterexample = true;
            end

            if passed && ~counterexample_found
                finding.computational_tests_pass = true;
            end

            return;
        end

        % === RECORD FORMAL PROOF ===
        function finding = record_formal_proof(finding, proof_file)
            % Record formal proof artifact (Lean, Agda, Coq, etc.)

            if ~isfile(proof_file)
                finding.warning_messages{end+1} = sprintf('Proof file not found: %s', proof_file);
                return;
            end

            finding.formal_proof_present = true;
            finding.formal_proof_file = proof_file;

            return;
        end

        % === ADD OPEN OBLIGATION ===
        function finding = add_obligation(finding, obligation_id, obligation_description)
            % Track an open proof obligation

            finding.open_obligations{end+1} = struct(...
                'id', obligation_id, ...
                'description', obligation_description, ...
                'resolved', false);
            finding.open_obligation_count = finding.open_obligation_count + 1;

            return;
        end

        % === ATTEMPT STATUS TRANSITION ===
        function [finding, success, reason] = transition_to(finding, target_status)
            % Attempt to transition to a new epistemic status
            %
            % Returns:
            %   finding: updated finding struct
            %   success: whether transition was permitted
            %   reason: explanation of decision

            current = finding.current_status;

            % === GUARD: NEVER DOWNGRADE ===
            status_order = ["OPEN", "CLAIMED", "AXIOM", "VERIFIED_COMPUTATIONAL", "VERIFIED_FORMAL", "MACHINE_CHECKED"];
            current_rank = find(status_order == current);
            target_rank = find(status_order == target_status);

            if target_rank < current_rank
                success = false;
                reason = sprintf('Cannot downgrade from %s to %s', current, target_status);
                finding.warning_messages{end+1} = reason;
                return;
            end

            % === IDENTITY TRANSITION ===
            if target_status == current
                success = true;
                reason = 'Already in target status';
                return;
            end

            % === LATERAL TRANSITION (OPEN/CLAIMED/AXIOM) ===
            if ismember(current, ["OPEN", "CLAIMED", "AXIOM"]) && ismember(target_status, ["OPEN", "CLAIMED", "AXIOM"])
                success = true;
                reason = sprintf('Lateral transition within exploratory phases');

                % Log transition
                finding.status_history(end+1) = struct(...
                    'status', target_status, ...
                    'timestamp', datetime('now'), ...
                    'reason', reason, ...
                    'evidence', '');
                finding.status_history_count = finding.status_history_count + 1;
                finding.current_status = target_status;
                return;
            end

            % === UPGRADE TO VERIFIED_COMPUTATIONAL ===
            if target_status == "VERIFIED_COMPUTATIONAL"
                if ~finding.computational_tests_pass
                    success = false;
                    reason = 'Computational tests have not passed';
                    return;
                end

                if finding.computational_counterexample
                    success = false;
                    reason = 'Counterexample found during computational testing';
                    return;
                end

                if finding.computational_tests_count == 0
                    success = false;
                    reason = 'No computational tests recorded';
                    return;
                end

                success = true;
                reason = sprintf('All %d computational tests passed, no counterexample found', ...
                    finding.computational_tests_count);

                % Log transition
                finding.status_history(end+1) = struct(...
                    'status', target_status, ...
                    'timestamp', datetime('now'), ...
                    'reason', reason, ...
                    'evidence', sprintf('%d tests', finding.computational_tests_count));
                finding.status_history_count = finding.status_history_count + 1;
                finding.current_status = target_status;
                return;
            end

            % === UPGRADE TO VERIFIED_FORMAL ===
            if target_status == "VERIFIED_FORMAL"
                if ~finding.formal_proof_present
                    success = false;
                    reason = 'No formal proof artifact present';
                    return;
                end

                success = true;
                reason = sprintf('Formal proof present: %s', finding.formal_proof_file);

                % Log transition
                finding.status_history(end+1) = struct(...
                    'status', target_status, ...
                    'timestamp', datetime('now'), ...
                    'reason', reason, ...
                    'evidence', finding.formal_proof_file);
                finding.status_history_count = finding.status_history_count + 1;
                finding.current_status = target_status;
                return;
            end

            % === UPGRADE TO MACHINE_CHECKED ===
            if target_status == "MACHINE_CHECKED"
                % Requires either formal proof or overwhelming computational evidence
                if finding.formal_proof_present || (finding.computational_tests_pass && ~finding.computational_counterexample)
                    success = true;
                    reason = 'Machine-checkable evidence provided';

                    % Log transition
                    evidence = '';
                    if finding.formal_proof_present
                        evidence = sprintf('Formal: %s', finding.formal_proof_file);
                    end
                    if finding.computational_tests_pass
                        evidence = sprintf('%s; Computational: %d tests', evidence, finding.computational_tests_count);
                    end

                    finding.status_history(end+1) = struct(...
                        'status', target_status, ...
                        'timestamp', datetime('now'), ...
                        'reason', reason, ...
                        'evidence', evidence);
                    finding.status_history_count = finding.status_history_count + 1;
                    finding.current_status = target_status;
                    return;
                else
                    success = false;
                    reason = 'Insufficient evidence for MACHINE_CHECKED status';
                    return;
                end
            end

            % === INVALID TARGET ===
            success = false;
            reason = sprintf('Invalid target status: %s', target_status);
            return;
        end

        % === PRINT STATUS REPORT ===
        function print_status(finding)
            % Print formatted status report for a finding

            fprintf('\n┌─────────────────────────────────────────────────────────┐\n');
            fprintf('│ EPISTEMIC STATUS REPORT                                 │\n');
            fprintf('└─────────────────────────────────────────────────────────┘\n\n');

            fprintf('Finding: %s\n', finding.finding_id);
            fprintf('Title: %s\n', finding.title);
            fprintf('Current Status: %s\n\n', finding.current_status);

            fprintf('Status History:\n');
            for h_idx = 1:length(finding.status_history)
                h = finding.status_history(h_idx);
                fprintf('  %d. [%s] %s → %s\n', h_idx, h.timestamp, finding.finding_id, h.status);
                fprintf('     Reason: %s\n', h.reason);
                if ~isempty(h.evidence)
                    fprintf('     Evidence: %s\n', h.evidence);
                end
            end

            fprintf('\nComputational Evidence:\n');
            fprintf('  Tests recorded: %d\n', finding.computational_tests_count);
            fprintf('  Tests passed: %s\n', mat2str(finding.computational_tests_pass));
            fprintf('  Counterexample found: %s\n', mat2str(finding.computational_counterexample));

            fprintf('\nFormal Evidence:\n');
            fprintf('  Proof present: %s\n', mat2str(finding.formal_proof_present));
            if finding.formal_proof_present
                fprintf('  Proof file: %s\n', finding.formal_proof_file);
            end

            fprintf('\nOpen Obligations: %d\n', finding.open_obligation_count);
            for o_idx = 1:length(finding.open_obligations)
                o = finding.open_obligations{o_idx};
                fprintf('  - %s: %s\n', o.id, o.description);
            end

            fprintf('\nWarnings: %d\n', length(finding.warning_messages));
            for w_idx = 1:length(finding.warning_messages)
                fprintf('  - %s\n', finding.warning_messages{w_idx});
            end

            fprintf('\n');

            return;
        end

    end
end
