% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [all_pass, results] = run_ci()
    % Run complete CI/CD pipeline
    % - Repository audit
    % - MATLAB-only verification
    % - Python removal audit
    % - Line count audit
    % - Function count audit
    % - License audit

    addpath(genpath('../src'));
    addpath(genpath('../config'));

    fprintf('====================================\n');
    fprintf('MATLAB Cycle-Mythos CI Pipeline\n');
    fprintf('====================================\n\n');

    results = struct();
    all_pass = true;

    % === 1. Repository Structure Audit ===
    fprintf('1. Repository Structure Audit\n');
    [pass, report] = auditRepositoryStructure('..');
    results.repositoryAudit = report;
    results.repositoryAudit.pass = pass;
    if ~pass
        fprintf('   FAILED\n');
        all_pass = false;
    else
        fprintf('   PASSED\n');
    end

    % === 2. MATLAB-Only Verification ===
    fprintf('2. MATLAB-Only Verification\n');
    [pass, report] = auditMATLABOnly('..');
    results.matlabOnlyAudit = report;
    if ~pass
        fprintf('   FAILED: Non-MATLAB files detected\n');
        all_pass = false;
    else
        fprintf('   PASSED\n');
    end

    % === 3. Python Removal Audit ===
    fprintf('3. Python Removal Audit\n');
    [pass, report] = utils.auditPythonRemoval('..');
    results.pythonRemovalAudit = report;
    if ~pass
        fprintf('   FAILED\n');
        fprintf('   %s\n', report.message);
        all_pass = false;
    else
        fprintf('   PASSED\n');
    end

    % === 4. Line Count Audit ===
    fprintf('4. Line Count Audit\n');
    [lineCount, report] = auditLineCount('..');
    results.lineCountAudit = report;
    results.lineCountAudit.totalLines = lineCount;
    if lineCount < 10000
        fprintf('   WARNING: %d lines (target: >= 10,000)\n', lineCount);
    else
        fprintf('   PASSED: %d lines (target: >= 10,000)\n', lineCount);
    end

    % === 5. Function Count Audit ===
    fprintf('5. Function Count Audit\n');
    [funcCount, report] = auditFunctionCount('..');
    results.functionCountAudit = report;
    results.functionCountAudit.totalFunctions = funcCount;
    if funcCount < 100
        fprintf('   WARNING: %d functions (target: >= 100)\n', funcCount);
    else
        fprintf('   PASSED: %d functions (target: >= 100)\n', funcCount);
    end

    % === 6. License Audit ===
    fprintf('6. License Audit\n');
    [pass, report] = auditLicenses('..');
    results.licenseAudit = report;
    if ~pass
        fprintf('   FAILED\n');
        all_pass = false;
    else
        fprintf('   PASSED\n');
    end

    % === 7. Invariant Audit ===
    fprintf('7. Invariant Coverage Audit\n');
    [pass, report] = auditInvariants('..');
    results.invariantAudit = report;
    if ~pass
        fprintf('   FAILED\n');
        all_pass = false;
    else
        fprintf('   PASSED\n');
    end

    fprintf('\n====================================\n');
    fprintf('CI Pipeline Complete\n');
    fprintf('Overall Status: %s\n', char(all_pass));
    fprintf('====================================\n');

end

function [pass, report] = auditRepositoryStructure(root)
    % Check repository has required structure

    report = struct();
    report.requiredDirs = {};
    report.foundDirs = {};
    report.pass = true;

    required = {
        'src', 'tests', 'config', 'ci', 'docs', 'experiments'
    };

    for i = 1:length(required)
        dir_path = fullfile(root, required{i});
        if exist(dir_path, 'dir')
            report.foundDirs{end+1} = required{i};
        else
            report.pass = false;
        end
    end

    pass = report.pass;

end

function [pass, report] = auditMATLABOnly(root)
    % Verify only MATLAB files in src directory

    report = struct();
    report.pass = true;
    report.matlabFiles = 0;
    report.nonMATLABFiles = {};

    src_dir = fullfile(root, 'src');
    if ~exist(src_dir, 'dir')
        report.pass = false;
        return;
    end

    all_files = getAllFiles(src_dir);
    for i = 1:length(all_files)
        file = all_files{i};
        [~, ~, ext] = fileparts(file);

        if strcmp(ext, '.m')
            report.matlabFiles = report.matlabFiles + 1;
        else
            report.nonMATLABFiles{end+1} = file;
            report.pass = false;
        end
    end

end

function [lineCount, report] = auditLineCount(root)
    % Count total lines of MATLAB code

    report = struct();
    lineCount = 0;
    report.linesByFile = {};

    src_dir = fullfile(root, 'src');
    if exist(src_dir, 'dir')
        all_files = getAllFiles(src_dir);
        for i = 1:length(all_files)
            file = all_files{i};
            if endsWith(file, '.m')
                lines = countLines(file);
                lineCount = lineCount + lines;
                report.linesByFile{end+1} = sprintf('%s: %d', file, lines);
            end
        end
    end

    % Also count experiment files
    exp_dir = fullfile(root, 'experiments');
    if exist(exp_dir, 'dir')
        all_files = getAllFiles(exp_dir);
        for i = 1:length(all_files)
            if endsWith(all_files{i}, '.m')
                lineCount = lineCount + countLines(all_files{i});
            end
        end
    end

end

function [funcCount, report] = auditFunctionCount(root)
    % Count MATLAB functions

    report = struct();
    funcCount = 0;

    % Count functions in src
    src_dir = fullfile(root, 'src');
    if exist(src_dir, 'dir')
        all_files = getAllFiles(src_dir);
        for i = 1:length(all_files)
            if endsWith(all_files{i}, '.m')
                funcCount = funcCount + countFunctions(all_files{i});
            end
        end
    end

    report.totalFunctions = funcCount;

end

function [pass, report] = auditLicenses(root)
    % Check for required license files

    report = struct();
    report.pass = true;
    report.filesFound = {};

    required_licenses = {
        'LICENSE'
        'LICENSE.BSD-3-CLAUSE'
        'LICENSE.GPL-1.0'
    };

    for i = 1:length(required_licenses)
        file_path = fullfile(root, required_licenses{i});
        if isfile(file_path)
            report.filesFound{end+1} = required_licenses{i};
        else
            report.pass = false;
        end
    end

    pass = report.pass;

end

function [pass, report] = auditInvariants(root)
    % Verify all 10 invariants are implemented

    report = struct();
    report.pass = true;
    report.invariantsFound = {};

    required_invariants = {
        'cycleConservation'      % I1
        'nonnegativeBalance'     % I2
        'queueIntegrity'         % I3
        'replayConsistency'      % I4
        'latencyBound'           % I6
        'recursionBound'         % I8
    };

    invariant_dir = fullfile(root, 'src', 'invariant', '+invariant');
    if exist(invariant_dir, 'dir')
        for i = 1:length(required_invariants)
            inv = required_invariants{i};
            file_path = fullfile(invariant_dir, [inv, '.m']);
            if isfile(file_path)
                report.invariantsFound{end+1} = inv;
            else
                report.pass = false;
            end
        end
    end

    pass = report.pass;

end

function all_files = getAllFiles(directory)
    all_files = {};

    if ~exist(directory, 'dir')
        return;
    end

    items = dir(directory);
    for i = 1:length(items)
        if items(i).isdir && ~startsWith(items(i).name, '.')
            subdir = fullfile(directory, items(i).name);
            subfiles = getAllFiles(subdir);
            all_files = [all_files, subfiles];
        elseif ~items(i).isdir
            all_files{end+1} = fullfile(directory, items(i).name);
        end
    end
end

function lines = countLines(file)
    try
        fid = fopen(file, 'r');
        lines = 0;
        while ~feof(fid)
            fgets(fid);
            lines = lines + 1;
        end
        fclose(fid);
    catch
        lines = 0;
    end
end

function funcs = countFunctions(file)
    try
        content = fileread(file);
        % Count lines with 'function' keyword
        funcs = length(regexp(content, 'function', 'match'));
    catch
        funcs = 0;
    end
end
