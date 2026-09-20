% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [pass, report] = auditPythonRemoval(repository_root)
    % Audit repository for Python execution infrastructure
    % Must detect and report all forbidden Python artifacts

    if nargin < 1
        repository_root = './';
    end

    report = struct();
    report.timestamp = datetime('now');
    report.repositoryRoot = repository_root;
    report.filesScanned = 0;
    report.pythonFilesFound = 0;
    report.forbiddenStringsFound = 0;
    report.forbiddenFiles = {};
    report.forbiddenCommands = {};
    report.pythonPatterns = {};

    % === Forbidden Patterns (ONLY used for detection) ===
    forbidden_file_patterns = {
        '*.py'
        '*.pyc'
        '*.pyo'
        'pyenv'
        'venv'
        'virtualenv'
        '.python-version'
    };

    forbidden_command_strings = {
        'python'
        'python3'
        'py.exe'
        'pip'
        'conda'
        'poetry'
        'subprocess'
    };

    % Scan repository
    all_files = getAllFiles(repository_root);

    for i = 1:length(all_files)
        file = all_files{i};
        report.filesScanned = report.filesScanned + 1;

        % Check filename
        [~, name, ext] = fileparts(file);
        filename = [name, ext];

        for j = 1:length(forbidden_file_patterns)
            pattern = forbidden_file_patterns{j};
            % Check if matches pattern
            if matchesPattern(filename, pattern)
                report.pythonFilesFound = report.pythonFilesFound + 1;
                report.forbiddenFiles{end+1} = file;
                break;
            end
        end

        % Check file contents (only for .m files and text files)
        if isTextFile(file) && ~contains(file, 'auditPythonRemoval')
            try
                content = fileread(file);
                for k = 1:length(forbidden_command_strings)
                    command = forbidden_command_strings{k};
                    if contains(lower(content), lower(command))
                        report.forbiddenStringsFound = report.forbiddenStringsFound + 1;
                        report.forbiddenCommands{end+1} = ...
                            sprintf('%s: %s', file, command);
                    end
                end
            catch
                % Skip binary files
            end
        end
    end

    % === Determine Pass/Fail ===
    pass = (report.pythonFilesFound == 0) && (report.forbiddenStringsFound == 0);

    report.pass = pass;
    report.message = sprintf(...
        'Files: %d | Python files: %d | Forbidden strings: %d | Status: %s', ...
        report.filesScanned, report.pythonFilesFound, ...
        report.forbiddenStringsFound, char(pass));

end

function files = getAllFiles(directory)
    % Recursively get all files in directory tree

    files = {};

    if ~exist(directory, 'dir')
        return;
    end

    % Get files in current directory
    items = dir(directory);

    for i = 1:length(items)
        if items(i).isdir && ~startsWith(items(i).name, '.')
            % Recurse into subdirectory
            subdir = fullfile(directory, items(i).name);
            subfiles = getAllFiles(subdir);
            files = [files, subfiles];
        elseif ~items(i).isdir
            % Add file
            files{end+1} = fullfile(directory, items(i).name);
        end
    end

end

function matches = matchesPattern(filename, pattern)
    % Simple glob pattern matching

    % Handle wildcards
    if startsWith(pattern, '*.')
        ext = pattern(2:end);
        matches = endsWith(filename, ext);
    else
        matches = strcmp(filename, pattern) || contains(filename, pattern);
    end

end

function is_text = isTextFile(file)
    % Check if file is likely text (not binary)

    [~, ~, ext] = fileparts(file);
    text_extensions = {'.m', '.txt', '.md', '.sh', '.py', '.yml', '.json', '.xml'};

    is_text = any(strcmp(ext, text_extensions));

end
