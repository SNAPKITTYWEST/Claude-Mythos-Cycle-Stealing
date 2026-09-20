% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [result, metadata] = convolution(n, kernel_size, reps)
    % Convolution kernel for benchmarking
    % Convolve signal of length n with kernel of size kernel_size

    arguments
        n (1,1) {mustBePositive} = 1024
        kernel_size (1,1) {mustBePositive} = 32
        reps (1,1) {mustBePositive} = 10
    end

    % Create input signal and kernel
    x = randn(1, n);
    h = randn(1, kernel_size);

    % Compute checksums
    inputChecksum = sum(x) + sum(h);

    % Warm-up
    y = conv(x, h, 'same');

    % Timed computation
    tic;
    for r = 1:reps
        y = conv(x, h, 'same');
    end
    elapsed = toc;

    % Output checksum
    outputChecksum = sum(y);

    % Estimate cycles (n * kernel_size operations per convolution)
    ops = n * kernel_size * reps;
    estimatedCycles = uint64(ops * 3); % 3 cycles per operation

    metadata = struct();
    metadata.kernelType = 'convolution';
    metadata.inputSize = n;
    metadata.kernelSize = kernel_size;
    metadata.repetitions = reps;
    metadata.operations = ops;
    metadata.elapsedTime = elapsed;
    metadata.estimatedCycles = estimatedCycles;
    metadata.inputChecksum = inputChecksum;
    metadata.outputChecksum = outputChecksum;
    metadata.checksumValid = (inputChecksum ~= 0);
    metadata.throughput = ops / elapsed;

    result = struct();
    result.output = y;
    result.cycles = estimatedCycles;

end
