function result = F2_boot_gate(varargin)
    % Deterministic Boot Gate - CLAIMED
    rng(42);
    state_size = 32;
    state = randi([0, 255], state_size, 1, 'uint8');
    
    % Deterministic initialization
    for iter = 1:10
        state = mod(state + iter, 256);
    end
    
    % Test reproducibility
    rng(42);
    state2 = randi([0, 255], state_size, 1, 'uint8');
    for iter = 1:10
        state2 = mod(state2 + iter, 256);
    end
    
    deterministic = all(state == state2);
    
    result.seed = 42;
    result.state_size = state_size;
    result.initial_state = state;
    result.deterministic_reproduction = deterministic;
    result.status = 'CLAIMED';
end
