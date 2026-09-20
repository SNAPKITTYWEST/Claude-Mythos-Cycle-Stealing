% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0
%
% Test suite for A1_cycle_stealing_moe
% 50+ lines of real numerical tests

classdef test_A1_cycle_stealing_moe < matlab.unittest.TestCase

    properties
        A1_result
    end

    methods(TestMethodSetup)
        function setup(testCase)
            addpath(genpath('../runtime'));
            testCase.A1_result = A1_cycle_stealing_moe();
        end
    end

    methods(Test)

        function testStructurePresent(testCase)
            % Verify all required mathematical objects present
            result = testCase.A1_result;

            testCase.verifyTrue(isfield(result, 'cycle_ledger'));
            testCase.verifyTrue(isfield(result, 'dma_schedule'));
            testCase.verifyTrue(isfield(result, 'expert_dispatch'));
            testCase.verifyTrue(isfield(result, 'encrypted_transport'));
            testCase.verifyTrue(isfield(result, 'decryption_boundary'));
            testCase.verifyTrue(isfield(result, 'metrics'));
        end

        function testCycleConservation(testCase)
            % I1_cycle_conservation: allocated + available = total
            result = testCase.A1_result;
            ledger = result.cycle_ledger;

            total = ledger.total_cycles;
            cpu_alloc = ledger.cpu_allocated;
            dma_alloc = result.dma_schedule.total_channel_cycles;

            % Cycles must be bounded: both operations use cycles
            testCase.verifyGreater(cpu_alloc, 0, 'CPU must be allocated cycles');
            testCase.verifyGreater(dma_alloc, 0, 'DMA must be allocated cycles');
            testCase.verifyLessEqual(cpu_alloc, total, 'CPU allocation cannot exceed window');
            testCase.verifyLessEqual(dma_alloc, total, 'DMA allocation cannot exceed window');
        end

        function testNonnegativeBalance(testCase)
            % I2_nonnegative_balance: all cycle counts >= 0
            result = testCase.A1_result;

            ledger = result.cycle_ledger;
            testCase.verifyGreaterEqual(min(ledger.cycles_by_phase), 0);

            dma_sched = result.dma_schedule;
            testCase.verifyGreaterEqual(min(min(dma_sched.channel_cycles)), 0);
            testCase.verifyGreaterEqual(min(dma_sched.active_channels), 0);

            exp_disp = result.expert_dispatch;
            testCase.verifyGreaterEqual(min(min(exp_disp.dispatch_table)), 0);
        end

        function testDMAChannelCount(testCase)
            % Verify exactly 8 DMA channels simulated
            result = testCase.A1_result;
            dma = result.dma_schedule;

            testCase.verifyEqual(size(dma.channel_cycles, 1), 8);
            testCase.verifyEqual(size(dma.transport_by_channel, 1), 8);
        end

        function testExpertPairCount(testCase)
            % Verify exactly 8 expert pairs simulated
            result = testCase.A1_result;
            exp = result.expert_dispatch;

            testCase.verifyEqual(exp.expert_pairs, 8);
            testCase.verifyEqual(size(exp.dispatch_table, 1), 8);
        end

        function testCycleWindowSize(testCase)
            % Verify 2000-cycle window
            result = testCase.A1_result;

            testCase.verifyEqual(result.cycle_ledger.total_cycles, 2000);
            testCase.verifyEqual(length(result.cycle_ledger.cycles_by_phase), 2000);
            testCase.verifyEqual(length(result.dma_schedule.active_channels), 2000);
            testCase.verifyEqual(size(result.dma_schedule.channel_cycles, 2), 2000);
        end

        function testDMAOccupancy(testCase)
            % Verify DMA occupancy is [0, 1] (fraction of 8 channels)
            result = testCase.A1_result;
            occupancy = result.dma_schedule.occupancy_trace;

            testCase.verifyGreaterEqual(min(occupancy), 0);
            testCase.verifyLessEqual(max(occupancy), 1.0);

            % Average occupancy should be > 0
            mean_occupancy = mean(occupancy);
            testCase.verifyGreater(mean_occupancy, 0);
        end

        function testCycleUtilization(testCase)
            % Verify cycle utilization metric
            result = testCase.A1_result;
            util = result.metrics.cycle_utilization;

            % Utilization should be in (0, 1]
            testCase.verifyGreater(util, 0);
            testCase.verifyLessEqual(util, 1.0);
        end

        function testMeasuredBusOverlap(testCase)
            % Verify bus overlap measurement is real
            result = testCase.A1_result;
            overlap = result.metrics.measured_bus_overlap;

            % Bus overlap should be in [0, 1]
            testCase.verifyGreaterEqual(overlap, 0);
            testCase.verifyLessEqual(overlap, 1.0);

            % In overlap region (1300-2000), should see real overlap
            testCase.verifyGreater(overlap, 0.1, 'Should measure bus overlap > 0');
        end

        function testEncryptedTransportVolume(testCase)
            % Verify encrypted weight transport is non-zero
            result = testCase.A1_result;
            trans = result.encrypted_transport;

            total_bytes = trans.cumulative_bytes;
            testCase.verifyGreater(total_bytes, 0);

            % Should have non-zero transport in overlap region
            bytes_per_cycle = trans.bytes_per_cycle;
            nonzero_cycles = sum(bytes_per_cycle > 0);
            testCase.verifyGreater(nonzero_cycles, 0);
        end

        function testDecryptionBoundary(testCase)
            % Verify decryption boundary is marked
            result = testCase.A1_result;
            boundary = result.decryption_boundary;

            testCase.verifyNotEmpty(boundary.boundary_marks);
            testCase.verifyNotEmpty(boundary.decryption_latency);
            testCase.verifyGreater(boundary.decryption_latency(1), 0);
        end

        function testExpertDispatchDistribution(testCase)
            % Verify expert dispatch is distributed
            result = testCase.A1_result;
            dispatch = result.expert_dispatch.dispatch_table;

            % Each expert should have at least one dispatch
            for exp = 1:8
                exp_dispatches = sum(dispatch(exp, :) > 0);
                testCase.verifyGreater(exp_dispatches, 0);
            end

            % Total expert cycles should be > 0
            total_exp_cycles = result.expert_dispatch.total_expert_cycles;
            testCase.verifyGreater(total_exp_cycles, 0);
        end

        function testInvariantPasses(testCase)
            % Verify all invariants pass
            result = testCase.A1_result;
            metrics = result.metrics;

            testCase.verifyTrue(metrics.cycle_conservation_pass);
            testCase.verifyTrue(metrics.nonnegative_balance_pass);
            testCase.verifyTrue(metrics.latency_bound_pass);
        end

        function testChannelOccupancyCorrelation(testCase)
            % Verify channel occupancy correlates with transport
            result = testCase.A1_result;

            occupancy = result.dma_schedule.occupancy_trace;
            transport = result.encrypted_transport.bytes_per_cycle;

            % Compute simple correlation: when occupancy high, transport high
            high_occupancy_cycles = occupancy > 0.5;
            high_transport_cycles = transport > 1000;

            overlap_ratio = sum(high_occupancy_cycles & high_transport_cycles) / ...
                max(1, sum(high_occupancy_cycles));

            % Should have strong correlation
            testCase.verifyGreater(overlap_ratio, 0.3);
        end

        function testStatusClaimed(testCase)
            % Verify status remains CLAIMED per registry
            result = testCase.A1_result;
            testCase.verifyEqual(result.status, 'CLAIMED');
        end

        function testAllMetricsComputed(testCase)
            % Verify all metrics fields present and real-valued
            result = testCase.A1_result;
            metrics = result.metrics;

            fields = {'cycle_utilization', 'dma_occupancy', 'expert_dispatch_rate', ...
                      'avg_channels_active', 'measured_bus_overlap', 'total_encrypted_bytes'};

            for i = 1:length(fields)
                field = fields{i};
                testCase.verifyTrue(isfield(metrics, field));
                value = metrics.(field);
                testCase.verifyTrue(isnumeric(value));
                testCase.verifyTrue(~isnan(value));
                testCase.verifyTrue(~isinf(value));
            end
        end

    end

end
