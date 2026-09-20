% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [result, metadata] = reduction(n, reps)
    % Reduction kernel (sum) for benchmarking
    % Reduce array of length n to single value

    arguments
        n (1,1) {mustBePositive} = 1000000
        reps (1,1) {mustBePositive} = 10
    end

    % Create input array
    x = randn(1, n);

    % Compute checksum
    inputChecksum = sum(x);

    % Warm-up
    s = sum(x);

    % Timed computation
    tic;
    for r = 1:reps
        s = sum(x);
    end
    elapsed = toc;

    outputChecksum = s;

    % Estimate cycles (n operations per reduction)
    ops = n * reps;
    estimatedCycles = uint64(ops * 2); % 2 cycles per operation

    metadata = struct();
    metadata.kernelType = 'reduction';
    metadata.inputSize = n;
    metadata.repetitions = reps;
    metadata.operations = ops;
    metadata.elapsedTime = elapsed;
    metadata.estimatedCycles = estimatedCycles;
    metadata.inputChecksum = inputChecksum;
    metadata.outputChecksum = outputChecksum;
    metadata.checksumValid = ~isnan(inputChecksum);
    metadata.throughput = ops / elapsed;

    result = struct();
    result.sum = s;
    result.cycles = estimatedCycles;

end
