% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [node, new_children] = expandNode(node, config, base_config)
    % Expand a node by creating and evaluating children

    arguments
        node struct
        config struct
        base_config struct
    end

    new_children = {};

    % Check depth limit
    if node.depth >= config.maxRecursionDepth
        node.status = 'terminal_depth';
        return;
    end

    % Check node count limit
    if node.childCount >= node.maxChildren
        node.status = 'terminal_children';
        return;
    end

    % Check cycle budget
    if node.cyclesUsed >= node.cycleBudget
        node.status = 'terminal_budget';
        return;
    end

    % Generate candidates for children
    candidate_count = min(node.maxChildren, ...
        floor(config.maxTotalNodes / (2 ^ (node.depth + 1))));

    candidates = mythos.generateCandidates(base_config, node.candidate.seed + node.nodeId, candidate_count);

    % Create child nodes
    for i = 1:length(candidates)
        child_id = uint64((node.nodeId * 1000) + i);

        child = recursion.createNode(child_id, node.nodeId, ...
            uint32(node.depth + 1), config, candidates{i});

        % Evaluate child
        [score, details] = mythos.evaluateCandidate(candidates{i}, 1);
        child.score = score;
        child.metrics = details;
        child.status = 'complete';

        new_children{i} = child;
        node.childCount = node.childCount + 1;
        node.cyclesUsed = node.cyclesUsed + child.cycleBudget;
    end

    node.children = new_children;
    node.status = 'expanded';

end
