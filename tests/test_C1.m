function tests = test_${cluster}()
    tests = functiontests(localfunctions);
end

function test_execution(testCase)
    result = ${cluster}();
    verifyNotEmpty(testCase, result);
    verifyTrue(testCase, ~strcmp(result.status, 'ERROR'));
end
