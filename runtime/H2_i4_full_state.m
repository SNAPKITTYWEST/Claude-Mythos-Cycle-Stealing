function result = H2_i4_full_state(varargin)
    % I4 Full State Theorem - OPEN
    state_dim = 8;
    test_states = randn(10, state_dim);
    
    i4_values = [];
    for s = 1:size(test_states, 1)
        i4 = sum(test_states(s, :).^4);
        i4_values = [i4_values; i4];
    end
    
    distinguishable = length(unique(round(i4_values, 10))) == size(test_states, 1);
    
    result.state_count = size(test_states, 1);
    result.state_dimension = state_dim;
    result.i4_values = i4_values;
    result.states_distinguishable = distinguishable;
    result.status = 'OPEN';
end
