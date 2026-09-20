% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

classdef TestScheduler < matlab.unittest.TestCase

    properties
        config
        queues
    end

    methods(TestMethodSetup)
        function setup(testCase)
            addpath(genpath('../src'));
            addpath(genpath('../config'));

            testCase.config = defaultConfig();
            testCase.config.workerCount = 4;

            % Initialize queues
            testCase.queues = struct();
            testCase.queues.type = 'FIFO';
            testCase.queues.workerQueues = repmat(struct(...
                'tasks', [], 'taskCount', 0), testCase.config.workerCount, 1);
            testCase.queues.taskLocation = zeros(10000, 1);
            testCase.queues.nextTaskId = uint64(1);
            testCase.queues.totalEnqueued = 0;
            testCase.queues.totalDequeued = 0;
            testCase.queues.eventCount = 0;
            testCase.queues.maxEvents = 1e6;
        end
    end

    methods(Test)

        function testEnqueue(testCase)
            % Test task enqueuing
            task = struct('taskId', 1, 'priority', 0, 'workUnits', 1000);
            [queues, taskId] = scheduler.enqueue(testCase.queues, uint32(1), task);

            testCase.verifyEqual(taskId, 1);
            testCase.verifyEqual(queues.workerQueues(1).taskCount, 1);
            testCase.verifyEqual(queues.totalEnqueued, 1);
        end

        function testDequeue(testCase)
            % Test task dequeuing
            task = struct('taskId', 1, 'priority', 0, 'workUnits', 1000);
            [testCase.queues, ~] = scheduler.enqueue(testCase.queues, uint32(1), task);

            [testCase.queues, dequeued_task, found] = scheduler.dequeue(testCase.queues, uint32(1));

            testCase.verifyTrue(found);
            testCase.verifyEqual(dequeued_task.taskId, 1);
            testCase.verifyEqual(testCase.queues.workerQueues(1).taskCount, 0);
        end

        function testPeek(testCase)
            % Test peeking at next task
            task = struct('taskId', 42, 'priority', 0);
            [testCase.queues, ~] = scheduler.enqueue(testCase.queues, uint32(2), task);

            [peeked_task, found] = scheduler.peek(testCase.queues, uint32(2));

            testCase.verifyTrue(found);
            testCase.verifyEqual(peeked_task.taskId, 42);
            % Queue should still have task after peek
            testCase.verifyEqual(testCase.queues.workerQueues(2).taskCount, 1);
        end

        function testIsEmpty(testCase)
            % Test empty queue detection
            empty1 = scheduler.isEmpty(testCase.queues, uint32(1));
            testCase.verifyTrue(empty1);

            task = struct('taskId', 1, 'priority', 0);
            [testCase.queues, ~] = scheduler.enqueue(testCase.queues, uint32(1), task);

            empty2 = scheduler.isEmpty(testCase.queues, uint32(1));
            testCase.verifyFalse(empty2);
        end

        function testQueueSize(testCase)
            % Test getting queue size
            task1 = struct('taskId', 1, 'priority', 0);
            task2 = struct('taskId', 2, 'priority', 0);

            [testCase.queues, ~] = scheduler.enqueue(testCase.queues, uint32(1), task1);
            [testCase.queues, ~] = scheduler.enqueue(testCase.queues, uint32(1), task2);

            size = scheduler.getQueueSize(testCase.queues, uint32(1));
            testCase.verifyEqual(size, 2);
        end

        function testQueueIntegrity(testCase)
            % Test I3: Queue Integrity invariant
            task1 = struct('taskId', 1, 'priority', 0);
            task2 = struct('taskId', 2, 'priority', 0);

            [testCase.queues, ~] = scheduler.enqueue(testCase.queues, uint32(1), task1);
            [testCase.queues, ~] = scheduler.enqueue(testCase.queues, uint32(2), task2);

            [pass, diag] = invariant.queueIntegrity(testCase.queues);

            testCase.verifyTrue(pass);
            testCase.verifyEqual(diag.uniqueTaskCount, 2);
        end

        function testQueueState(testCase)
            % Test queue state snapshot
            task1 = struct('taskId', 1, 'priority', 0);
            task2 = struct('taskId', 2, 'priority', 0);
            task3 = struct('taskId', 3, 'priority', 0);

            [testCase.queues, ~] = scheduler.enqueue(testCase.queues, uint32(1), task1);
            [testCase.queues, ~] = scheduler.enqueue(testCase.queues, uint32(1), task2);
            [testCase.queues, ~] = scheduler.enqueue(testCase.queues, uint32(2), task3);

            state = scheduler.queueState(testCase.queues);

            testCase.verifyEqual(state.totalEnqueued, 3);
            testCase.verifyEqual(state.maxDepth, 2);
            testCase.verifyEqual(state.minDepth, 0);
        end

        function testFIFOOrdering(testCase)
            % Test FIFO queue ordering
            for i = 1:5
                task = struct('taskId', i, 'priority', 0);
                [testCase.queues, ~] = scheduler.enqueue(testCase.queues, uint32(1), task);
            end

            for i = 1:5
                [testCase.queues, task, found] = scheduler.dequeue(testCase.queues, uint32(1));
                testCase.verifyTrue(found);
                testCase.verifyEqual(task.taskId, i);
            end
        end

        function testMultipleWorkerQueues(testCase)
            % Test queuing across multiple workers
            for w = 1:testCase.config.workerCount
                for t = 1:3
                    task = struct('taskId', (w-1)*3 + t, 'priority', 0);
                    [testCase.queues, ~] = scheduler.enqueue(testCase.queues, uint32(w), task);
                end
            end

            total = 0;
            for w = 1:testCase.config.workerCount
                total = total + scheduler.getQueueSize(testCase.queues, uint32(w));
            end

            testCase.verifyEqual(total, 12);
        end

    end

end
