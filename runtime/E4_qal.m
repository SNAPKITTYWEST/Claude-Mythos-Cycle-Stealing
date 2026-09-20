function result = E4_qal(varargin)
    % QAL (Quantum Approximation Limit) - CLAIMED
    
    f_rep = 0.7;
    f_mut = 0.3;
    generation_count = 100;
    prime_layers = 5;
    
    population = randn(generation_count, 10);
    fitness = [];
    
    for gen = 1:generation_count
        for layer = 1:prime_layers
            fitness = [fitness; sum(population(gen, :).^2)];
        end
    end
    
    result.f_rep = f_rep;
    result.f_mut = f_mut;
    result.generation_count = generation_count;
    result.prime_layers = prime_layers;
    result.fitness_evaluations = length(fitness);
    result.mean_fitness = mean(fitness);
    result.status = 'CLAIMED';
end
