% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [result, metadata] = benchmarkKernel(kernel_type, kernel_size, reps)
    % Dispatch to appropriate kernel based on type
    % Returns estimated cycles and metadata

    arguments
        kernel_type (1,:) char = 'matrix_multiply'
        kernel_size (1,1) {mustBePositive} = 256
        reps (1,1) {mustBePositive} = 10
    end

    switch kernel_type
        case 'matrix_multiply'
            [result, metadata] = kernels.matrixMultiply(kernel_size, reps);

        case 'fft'
            [result, metadata] = kernels.fftKernel(kernel_size, reps);

        case 'convolution'
            [result, metadata] = kernels.convolution(kernel_size, max(1, floor(kernel_size/8)), reps);

        case 'sort'
            [result, metadata] = kernels.sortKernel(kernel_size, reps);

        case 'reduction'
            [result, metadata] = kernels.reduction(kernel_size, reps);

        otherwise
            error('Unknown kernel type: %s', kernel_type);
    end

    % Add type to metadata
    metadata.requestedType = kernel_type;

end
