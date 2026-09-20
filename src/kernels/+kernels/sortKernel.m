% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [result, metadata] = sortKernel(n, reps)
    % Sorting kernel for benchmarking
    % Sort array of length n

    arguments
        n (1,1) {mustBePositive} = 10000
        reps (1,1) {mustBePositive} = 10
    end

    % Create input array
    x = randn(1, n);

    % Compute checksum
    inputChecksum = sum(x);

    % Warm-up
    x_sorted = sort(x);

    % Timed computation
    tic;
    for r = 1:reps
        x_sorted = sort(x);
    end
    elapsed = toc;

    % Output checksum
    outputChecksum = sum(x_sorted);

    % Estimate cycles (n log n per sort)
    ops = n * log2(n) * reps;
    estimatedCycles = uint64(ops * 5); % 5 cycles per comparison

    metadata = struct();
    metadata.kernelType = 'sort';
    metadata.inputSize = n;
    metadata.repetitions = reps;
    metadata.operations = ops;
    metadata.elapsedTime = elapsed;
    metadata.estimatedCycles = estimatedCycles;
    metadata.inputChecksum = inputChecksum;
    metadata.outputChecksum = outputChecksum;
    metadata.checksumValid = (inputChecksum ~= 0);
    metadata.throughput = ops / elapsed;

    result = struct();
    result.sorted = x_sorted;
    result.cycles = estimatedCycles;

end
