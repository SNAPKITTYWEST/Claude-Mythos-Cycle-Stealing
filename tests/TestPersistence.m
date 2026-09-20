% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

classdef TestPersistence < matlab.unittest.TestCase

    properties
        config
        testDir
    end

    methods(TestMethodSetup)
        function setup(testCase)
            addpath(genpath('../src'));
            addpath(genpath('../config'));

            testCase.config = defaultConfig();
            testCase.testDir = tempdir();
        end
    end

    methods(Test)

        function testSaveAndLoadExperiment(testCase)
            % Test saving and loading experiment results
            testCase.config.seed = 12345;

            % Run experiment
            result = run_experiment('baseline');

            % Save
            filename = fullfile(testCase.testDir, 'test_exp.mat');
            save(filename, 'result', 'testCase.config');

            testCase.verifyTrue(isfile(filename));

            % Load
            loaded_data = load(filename);
            loaded_result = loaded_data.result;

            testCase.verifyEqual(result.statistics.totalTasksCompleted, ...
                loaded_result.statistics.totalTasksCompleted);
        end

        function testEventLogSerialization(testCase)
            % Test event log can be serialized and deserialized
            testCase.config.seed = 54321;

            result = run_experiment('baseline');
            events = result.ledger.events;

            % Serialize (save to file)
            filename = fullfile(testCase.testDir, 'events.mat');
            save(filename, 'events');

            testCase.verifyTrue(isfile(filename));

            % Deserialize (load from file)
            loaded_data = load(filename);
            loaded_events = loaded_data.events;

            testCase.verifyEqual(length(events), length(loaded_events));
        end

        function testConfigurationSerialization(testCase)
            % Test configuration serialization
            config = testCase.config;

            % Save
            filename = fullfile(testCase.testDir, 'config.mat');
            save(filename, 'config');

            testCase.verifyTrue(isfile(filename));

            % Load
            loaded_data = load(filename);
            loaded_config = loaded_data.config;

            testCase.verifyEqual(config.seed, loaded_config.seed);
            testCase.verifyEqual(config.workerCount, loaded_config.workerCount);
        end

        function testLedgerSerialization(testCase)
            % Test ledger serialization
            testCase.config.seed = 99999;

            result = run_experiment('baseline');
            ledger_orig = result.ledger;

            % Save
            filename = fullfile(testCase.testDir, 'ledger.mat');
            save(filename, 'ledger_orig');

            % Load
            loaded_data = load(filename);
            ledger_loaded = loaded_data.ledger_orig;

            testCase.verifyEqual(ledger_orig.totalInitialCycles, ...
                ledger_loaded.totalInitialCycles);
            testCase.verifyEqual(ledger_orig.consumedCycles, ...
                ledger_loaded.consumedCycles);
        end

        function testStatisticsSerialization(testCase)
            % Test statistics serialization
            testCase.config.seed = 11111;

            result = run_experiment('baseline');
            stats = result.statistics;

            % Save
            filename = fullfile(testCase.testDir, 'stats.mat');
            save(filename, 'stats');

            % Load
            loaded_data = load(filename);
            loaded_stats = loaded_data.stats;

            testCase.verifyEqual(stats.totalTasksCompleted, ...
                loaded_stats.totalTasksCompleted);
        end

        function testMultipleResultsArchive(testCase)
            % Archive multiple experiment results
            results_array = {};

            for i = 1:3
                testCase.config.seed = 10000 + i;
                results_array{i} = run_experiment('baseline');
            end

            % Save all
            filename = fullfile(testCase.testDir, 'archive.mat');
            save(filename, 'results_array');

            testCase.verifyTrue(isfile(filename));

            % Load all
            loaded_data = load(filename);
            loaded_results = loaded_data.results_array;

            testCase.verifyEqual(length(results_array), length(loaded_results));
        end

        function testCheckpointRecovery(testCase)
            % Test checkpoint and recovery
            testCase.config.seed = 22222;

            % Run and save checkpoint
            result = run_experiment('baseline');
            snap_original = ledger.snapshot(result.ledger);

            checkpoint_file = fullfile(testCase.testDir, 'checkpoint.mat');
            save(checkpoint_file, 'result', 'snap_original');

            testCase.verifyTrue(isfile(checkpoint_file));

            % Recover from checkpoint
            loaded = load(checkpoint_file);
            snap_recovered = loaded.snap_original;

            testCase.verifyEqual(snap_original.totalInitialCycles, ...
                snap_recovered.totalInitialCycles);
        end

        function testTraceExport(testCase)
            % Test exporting execution trace
            testCase.config.seed = 33333;

            result = run_experiment('baseline');
            events = result.ledger.events;

            % Export as text
            trace_file = fullfile(testCase.testDir, 'trace.txt');
            fid = fopen(trace_file, 'w');

            for i = 1:min(100, length(events))
                event = events(i);
                fprintf(fid, '%d,%s,%d,%d\n', event.eventId, event.operation, ...
                    event.workerId, event.cycles);
            end

            fclose(fid);
            testCase.verifyTrue(isfile(trace_file));
        end

        function testResultArchiveIntegrity(testCase)
            % Verify archived results maintain integrity
            testCase.config.seed = 44444;

            result_original = run_experiment('baseline');

            % Archive
            archive_file = fullfile(testCase.testDir, 'archive_integrity.mat');
            save(archive_file, 'result_original');

            % Load and verify
            loaded = load(archive_file);
            result_loaded = loaded.result_original;

            % Invariants should still pass
            testCase.verifyTrue(result_loaded.invariantPass);

            % Statistics should match
            testCase.verifyEqual(result_original.statistics.totalTasksCompleted, ...
                result_loaded.statistics.totalTasksCompleted);
        end

    end

    methods(TestMethodTeardown)
        function cleanup(testCase)
            % Clean up test files
            % Files left in tempdir for inspection
        end
    end

end
