% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function hash = hashState(state)
    % Compute deterministic hash of execution state
    % Used for reproducibility verification

    % Convert state to string representation
    state_str = '';

    % Hash numeric fields
    if isfield(state, 'workerCycles')
        state_str = [state_str, sprintf('%d', sum(state.workerCycles))];
    end

    if isfield(state, 'consumedCycles')
        state_str = [state_str, sprintf('%d', state.consumedCycles)];
    end

    if isfield(state, 'eventCount')
        state_str = [state_str, sprintf('%d', state.eventCount)];
    end

    if isfield(state, 'stolenCycles')
        state_str = [state_str, sprintf('%d', state.stolenCycles)];
    end

    % Compute hash
    hash = uint32(sum(uint8(state_str)));

end
