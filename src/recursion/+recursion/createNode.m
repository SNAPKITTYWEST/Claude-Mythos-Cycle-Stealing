% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function node = createNode(nodeId, parentId, depth, config, candidate)
    % Create a node in the recursive exploration tree

    arguments
        nodeId (1,1) uint64 {mustBePositive}
        parentId (1,1) uint64
        depth (1,1) uint32 {mustBeNonnegative}
        config struct
        candidate struct
    end

    node = struct();

    % === Node Identification ===
    node.nodeId = nodeId;
    node.parentId = parentId;
    node.depth = depth;
    node.isRoot = (parentId == 0);

    % === Configuration ===
    node.config = config;
    node.candidate = candidate;

    % === State ===
    node.status = 'created'; % 'created', 'evaluating', 'complete', 'failed'
    node.creationTime = datetime('now');

    % === Results ===
    node.result = [];
    node.score = 0;
    node.metrics = struct();

    % === Children ===
    node.children = {};
    node.childCount = 0;
    node.maxChildren = config.maxNodesPerLevel;

    % === Cycle Budget ===
    node.cycleBudget = config.recursionCycleBudget / (2 ^ (depth - 1));
    node.cyclesUsed = 0;

end
