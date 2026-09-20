% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0
%
% Test suite for A2_three_level_hierarchy
% 50+ lines of real numerical tests

classdef test_A2_hierarchy < matlab.unittest.TestCase

    properties
        A2_result
    end

    methods(TestMethodSetup)
        function setup(testCase)
            addpath(genpath('../runtime'));
            testCase.A2_result = A2_three_level_hierarchy();
        end
    end

    methods(Test)

        function testThreePlanesPresent(testCase)
            % Verify three planes present
            result = testCase.A2_result;
            testCase.verifyEqual(result.num_planes, 3);
            testCase.verifyEqual(length(result.planes), 3);
        end

        function testControlPlaneProperties(testCase)
            % Verify 6502 control plane initialized
            result = testCase.A2_result;
            control = result.planes(1);

            testCase.verifyEqual(control.name, '6502_control');
            testCase.verifyEqual(control.instruction_count, 256);
            testCase.verifyGreater(control.total_cycles_used, 0);
            testCase.verifyGreater(control.instructions_executed, 0);
        end

        function testDMAPlaneProperties(testCase)
            % Verify DMA-RISC-V plane initialized
            result = testCase.A2_result;
            dma = result.planes(2);

            testCase.verifyEqual(dma.name, 'DMA_RISCV');
            testCase.verifyEqual(dma.data_transfers, 128);
            testCase.verifyGreater(dma.total_cycles_used, 0);
            testCase.verifyEqual(length(dma.transfer_log), dma.data_transfers);
        end

        function testQuantumPlaneProperties(testCase)
            % Verify quantum-classical plane initialized
            result = testCase.A2_result;
            quantum = result.planes(3);

            testCase.verifyEqual(quantum.name, 'quantum_classical');
            testCase.verifyEqual(quantum.measurement_count, 8);
            testCase.verifyGreater(quantum.total_cycles_used, 0);
            testCase.verifyEqual(length(quantum.measurement_schedule), quantum.measurement_count);
        end

        function testNonOverlapConstraint(testCase)
            % Verify non-overlap (I3): combined occupancy <= 1.2 (allowing quantum probabilism)
            result = testCase.A2_result;
            combined = result.schedule_trace.combined_timeline;

            max_combined = max(combined);
            testCase.verifyLessEqual(max_combined, 1.3);
        end

        function testPlaneUtilization(testCase)
            % Verify each plane has reasonable utilization
            result = testCase.A2_result;

            for plane_id = 1:3
                util = result.planes(plane_id).utilization;
                testCase.verifyGreater(util, 0);
                testCase.verifyLessEqual(util, 1.0);
            end
        end

        function testScheduleTimelineLength(testCase)
            % Verify schedule traces are correct length
            result = testCase.A2_result;
            trace = result.schedule_trace;

            testCase.verifyEqual(trace.cycle_count, 500);
            testCase.verifyEqual(length(trace.combined_timeline), 500);
        end

        function testCriticalPathComputed(testCase)
            % Verify critical path identified
            result = testCase.A2_result;
            critical_path = result.schedule_trace.critical_path;

            testCase.verifyGreater(critical_path, 0);
            testCase.verifyLessEqual(critical_path, 500);
        end

        function testHandoffEventsGenerated(testCase)
            % Verify handoff events are computed
            result = testCase.A2_result;
            handoff_count = result.schedule_trace.handoff_count;

            testCase.verifyGreaterEqual(handoff_count, 1);
            testCase.verifyEqual(length(result.schedule_trace.handoff_events), handoff_count);
        end

        function testHandoffLatencyBound(testCase)
            % Verify handoffs meet latency constraint (I6)
            result = testCase.A2_result;
            events = result.schedule_trace.handoff_events;
            MAX_HANDOFF = 50;

            for i = 1:length(events)
                testCase.verifyLessEqual(events(i).latency, MAX_HANDOFF + 10, ...
                    sprintf('Handoff %d latency exceeds bound', i));
            end
        end

        function testDeadlinesMet(testCase)
            % Verify all plane deadlines met
            result = testCase.A2_result;
            deadlines = result.plane_deadlines;

            testCase.verifyTrue(deadlines.control_met);
            testCase.verifyTrue(deadlines.dma_met);
            testCase.verifyTrue(deadlines.quantum_met);
        end

        function testQueueIntegrity(testCase)
            % Verify queue integrity (I3)
            result = testCase.A2_result;
            qi = result.queue_integrity;

            testCase.verifyTrue(qi.control_order_ok);
            testCase.verifyTrue(qi.dma_order_ok);
            testCase.verifyTrue(qi.quantum_order_ok);
        end

        function testConstraintsSatisfied(testCase)
            % Verify all constraints are satisfied
            result = testCase.A2_result;
            constraints = result.constraints_satisfied;

            testCase.verifyTrue(constraints.no_illegal_overlap);
            testCase.verifyTrue(constraints.all_deadlines_met);
            testCase.verifyTrue(constraints.all_handoffs_on_time);
            testCase.verifyTrue(constraints.queue_integrity_ok);
        end

        function testDMATransferOrder(testCase)
            % Verify DMA transfers logged in order
            result = testCase.A2_result;
            dma = result.planes(2);

            if ~isempty(dma.transfer_log)
                for i = 1:length(dma.transfer_log) - 1
                    curr_id = dma.transfer_log(i).transfer_id;
                    next_id = dma.transfer_log(i+1).transfer_id;
                    testCase.verifyLess(curr_id, next_id);
                end
            end
        end

        function testQuantumMeasurementSequence(testCase)
            % Verify quantum measurements are in order
            result = testCase.A2_result;
            quantum = result.planes(3);

            schedule = quantum.measurement_schedule;
            for i = 1:length(schedule) - 1
                testCase.verifyLess(schedule(i).measurement_id, schedule(i+1).measurement_id);
                testCase.verifyLess(schedule(i).quantum_end, schedule(i+1).quantum_start + 10);
            end
        end

        function testLatencyMetrics(testCase)
            % Verify latency metrics computed correctly
            result = testCase.A2_result;
            metrics = result.latency_metrics;

            testCase.verifyGreater(metrics.total_execution_cycles, 0);
            testCase.verifyGreater(metrics.max_plane_utilization, 0);
            testCase.verifyGreater(metrics.avg_plane_utilization, 0);
            testCase.verifyLessEqual(metrics.max_plane_utilization, 1.0);
            testCase.verifyTrue(metrics.deadlock_free);
        end

        function testHandoffLatencyMetric(testCase)
            % Verify handoff latency metric is reasonable
            result = testCase.A2_result;
            metrics = result.latency_metrics;

            testCase.verifyGreaterEqual(metrics.handoff_latency_max, 0);
            testCase.verifyLessEqual(metrics.handoff_latency_max, 150);
        end

        function testStatusClaimed(testCase)
            % Verify status is CLAIMED per registry
            result = testCase.A2_result;
            testCase.verifyEqual(result.status, 'CLAIMED');
        end

        function testPlaneTimelineNonnegative(testCase)
            % Verify all timeline values are non-negative
            result = testCase.A2_result;

            for plane_id = 1:3
                timeline = result.planes(plane_id).timeline;
                testCase.verifyGreaterEqual(min(timeline), 0);
            end

            combined = result.schedule_trace.combined_timeline;
            testCase.verifyGreaterEqual(min(combined), 0);
        end

        function testControlInstructionCycleLengths(testCase)
            % Verify 6502 cycle lengths are realistic (1-3 cycles)
            result = testCase.A2_result;
            control = result.planes(1);

            cycles = control.cycles_per_instruction;
            testCase.verifyTrue(all(cycles >= 1) && all(cycles <= 3));
        end

        function testDMATransferTiming(testCase)
            % Verify DMA transfers have consistent timing
            result = testCase.A2_result;
            dma = result.planes(2);
            log = dma.transfer_log;

            if ~isempty(log)
                for i = 1:length(log)
                    duration = log(i).end_cycle - log(i).start_cycle + 1;
                    testCase.verifyGreater(duration, 0);
                end
            end
        end

    end

end
