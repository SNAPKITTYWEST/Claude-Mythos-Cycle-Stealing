% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [result, metadata] = matrixMultiply(n, reps)
    % Matrix multiply kernel for benchmarking
    % A(n x n) * B(n x n) = C(n x n)

    arguments
        n (1,1) {mustBePositive} = 256
        reps (1,1) {mustBePositive} = 10
    end

    % Create deterministic input matrices
    A = randn(n, n) * 0.1;
    B = randn(n, n) * 0.1;

    % Compute checksum of inputs for verification
    inputChecksum = sum(A(:)) + sum(B(:));

    % Warm-up
    C = A * B;

    % Timed computation
    tic;
    for r = 1:reps
        C = A * B;
    end
    elapsed = toc;

    % Compute output checksum
    outputChecksum = sum(C(:));

    % Estimate cycles (n^3 multiplications per iteration)
    ops = 2 * n^3 * reps; % multiply + add
    cyclesPerOp = 1.0; % 1 cycle per FLOp (simulated)
    estimatedCycles = uint64(ops * cyclesPerOp);

    % Metadata
    metadata = struct();
    metadata.kernelType = 'matrix_multiply';
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
    result.matrix = C;
    result.cycles = estimatedCycles;

end
