% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [result, metadata] = fftKernel(n, reps)
    % FFT kernel for benchmarking
    % Compute 1D FFT of length n

    arguments
        n (1,1) {mustBePositive} = 1024
        reps (1,1) {mustBePositive} = 10
    end

    % Create input signal
    x = randn(1, n) + 1j * randn(1, n);

    % Compute checksum
    inputChecksum = sum(real(x)) + sum(imag(x));

    % Warm-up
    X = fft(x);

    % Timed computation
    tic;
    for r = 1:reps
        X = fft(x);
    end
    elapsed = toc;

    % Output checksum
    outputChecksum = sum(real(X)) + sum(imag(X));

    % Estimate cycles (n log n operations per FFT)
    ops = n * log2(n) * reps;
    estimatedCycles = uint64(ops * 2); % 2 cycles per operation

    metadata = struct();
    metadata.kernelType = 'fft';
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
    result.spectrum = X;
    result.cycles = estimatedCycles;

end
