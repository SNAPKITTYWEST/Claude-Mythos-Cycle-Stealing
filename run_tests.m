% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function results = run_tests()
    % Run complete test suite

    addpath(genpath('./src'));
    addpath(genpath('./config'));

    % Create test suite
    suite = matlab.unittest.TestSuite.fromFolder('./tests');

    % Run tests
    runner = matlab.unittest.TextTestRunner('Verbosity', matlab.unittest.Verbosity.Verbose);
    results = runner.run(suite);

    % Print summary
    fprintf('\n====== TEST SUMMARY ======\n');
    fprintf('Tests run: %d\n', length(results));
    fprintf('Passed: %d\n', sum([results.Passed]));
    fprintf('Failed: %d\n', sum([results.Failed]));

end
