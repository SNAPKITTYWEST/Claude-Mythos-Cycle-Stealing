% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

classdef TestKernels < matlab.unittest.TestCase

    methods(TestMethodSetup)
        function setup(testCase)
            addpath(genpath('../src'));
        end
    end

    methods(Test)

        function testMatrixMultiply(testCase)
            % Test matrix multiply kernel
            [result, metadata] = kernels.matrixMultiply(64, 5);

            testCase.verifyNotEmpty(result.matrix);
            testCase.verifyGreater(metadata.estimatedCycles, 0);
            testCase.verifyTrue(metadata.checksumValid);
            testCase.verifyEqual(metadata.kernelType, 'matrix_multiply');
        end

        function testFFT(testCase)
            % Test FFT kernel
            [result, metadata] = kernels.fftKernel(512, 5);

            testCase.verifyNotEmpty(result.spectrum);
            testCase.verifyGreater(metadata.estimatedCycles, 0);
            testCase.verifyTrue(metadata.checksumValid);
            testCase.verifyEqual(metadata.kernelType, 'fft');
        end

        function testConvolution(testCase)
            % Test convolution kernel
            [result, metadata] = kernels.convolution(512, 32, 5);

            testCase.verifyNotEmpty(result.output);
            testCase.verifyGreater(metadata.estimatedCycles, 0);
            testCase.verifyTrue(metadata.checksumValid);
            testCase.verifyEqual(metadata.kernelType, 'convolution');
        end

        function testSort(testCase)
            % Test sorting kernel
            [result, metadata] = kernels.sortKernel(5000, 5);

            testCase.verifyNotEmpty(result.sorted);
            testCase.verifyGreater(metadata.estimatedCycles, 0);
            testCase.verifyEqual(metadata.kernelType, 'sort');
        end

        function testReduction(testCase)
            % Test reduction kernel
            [result, metadata] = kernels.reduction(100000, 5);

            testCase.verifyNotEmpty(result.sum);
            testCase.verifyGreater(metadata.estimatedCycles, 0);
            testCase.verifyEqual(metadata.kernelType, 'reduction');
        end

        function testBenchmarkDispatch(testCase)
            % Test kernel factory
            [result, metadata] = kernels.benchmarkKernel('matrix_multiply', 64, 3);

            testCase.verifyEqual(metadata.requestedType, 'matrix_multiply');
            testCase.verifyGreater(metadata.estimatedCycles, 0);
        end

        function testKernelDeterminism(testCase)
            % Test kernel determinism
            [result1, meta1] = kernels.matrixMultiply(128, 3);
            [result2, meta2] = kernels.matrixMultiply(128, 3);

            % Checksums should match (deterministic)
            testCase.verifyEqual(meta1.inputChecksum, meta2.inputChecksum);
        end

    end

end
