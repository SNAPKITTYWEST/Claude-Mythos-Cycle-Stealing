% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function rng_state = deterministicSeed(seed)
    % Set deterministic RNG state from seed
    % Returns the RNG state for later restoration

    arguments
        seed (1,1) uint64 {mustBeNonnegative}
    end

    % Use a hash of the seed to initialize RNG
    % This ensures bit-exact reproducibility across runs
    rng(seed, 'twister');
    rng_state = rng();
end
