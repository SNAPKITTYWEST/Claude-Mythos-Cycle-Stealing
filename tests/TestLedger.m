% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

classdef TestLedger < matlab.unittest.TestCase

    properties
        config
        ledger
    end

    methods(TestMethodSetup)
        function setup(testCase)
            addpath(genpath('../src'));
            addpath(genpath('../config'));

            testCase.config = defaultConfig();
            testCase.config.workerCount = 4;
            testCase.config.totalInitialCycles = 1e6;
            testCase.ledger = ledger.create(testCase.config.totalInitialCycles, testCase.config);
        end
    end

    methods(Test)

        function testCreateLedger(testCase)
            % Test ledger creation
            testCase.verifyNotEmpty(testCase.ledger);
            testCase.verifyEqual(testCase.ledger.totalInitialCycles, 1e6);
            testCase.verifyEqual(testCase.ledger.availableCycles, 1e6);
            testCase.verifyEqual(testCase.ledger.allocatedCycles, 0);
        end

        function testAllocate(testCase)
            % Test cycle allocation
            [leg, eventId] = ledger.allocate(testCase.ledger, uint32(1), 1000);
            testCase.verifyEqual(leg.workerCycles(1), 1000);
            testCase.verifyEqual(leg.allocatedCycles, 1000);
            testCase.verifyGreater(eventId, 0);
        end

        function testConservation(testCase)
            % Test I1: Cycle Conservation
            [testCase.ledger, ~] = ledger.allocate(testCase.ledger, uint32(1), 1000);
            [testCase.ledger, ~] = ledger.allocate(testCase.ledger, uint32(2), 2000);

            [pass, diag] = invariant.cycleConservation(testCase.ledger);
            testCase.verifyTrue(pass);
            testCase.verifyEqual(diag.difference, 0);
        end

        function testConsume(testCase)
            % Test cycle consumption
            [testCase.ledger, ~] = ledger.allocate(testCase.ledger, uint32(1), 1000);
            [testCase.ledger, success, ~] = ledger.consume(testCase.ledger, uint32(1), 500);

            testCase.verifyTrue(success);
            testCase.verifyEqual(testCase.ledger.workerCycles(1), 500);
            testCase.verifyEqual(testCase.ledger.consumedCycles, 500);
        end

        function testOverConsume(testCase)
            % Test that overconsumption is prevented
            [testCase.ledger, ~] = ledger.allocate(testCase.ledger, uint32(1), 1000);
            [testCase.ledger, success, ~] = ledger.consume(testCase.ledger, uint32(1), 2000);

            testCase.verifyFalse(success); % Should fail
            testCase.verifyEqual(testCase.ledger.workerCycles(1), 1000); % Unchanged
        end

        function testTransfer(testCase)
            % Test cycle stealing (transfer)
            [testCase.ledger, ~] = ledger.allocate(testCase.ledger, uint32(1), 1000);
            [testCase.ledger, ~] = ledger.allocate(testCase.ledger, uint32(2), 100);

            [testCase.ledger, success, ~] = ledger.transfer(...
                testCase.ledger, uint32(1), uint32(2), 300);

            testCase.verifyTrue(success);
            testCase.verifyEqual(testCase.ledger.workerCycles(1), 700);
            testCase.verifyEqual(testCase.ledger.workerCycles(2), 400);
        end

        function testNonnegativeBalance(testCase)
            % Test I2: Nonnegative Balances
            [testCase.ledger, ~] = ledger.allocate(testCase.ledger, uint32(1), 1000);

            [pass, ~] = invariant.nonnegativeBalance(testCase.ledger);
            testCase.verifyTrue(pass);
        end

        function testValidation(testCase)
            % Test ledger validation
            [testCase.ledger, ~] = ledger.allocate(testCase.ledger, uint32(1), 1000);

            [isValid, violations, report] = ledger.validate(testCase.ledger);
            testCase.verifyTrue(isValid);
            testCase.verifyEmpty(violations);
            testCase.verifyTrue(report.I1_Conservation);
        end

        function testSnapshot(testCase)
            % Test ledger snapshot
            [testCase.ledger, ~] = ledger.allocate(testCase.ledger, uint32(1), 1000);
            snap = ledger.snapshot(testCase.ledger);

            testCase.verifyEqual(snap.allocatedCycles, 1000);
            testCase.verifyFalse(snap.conservationViolation);
        end

    end

end
