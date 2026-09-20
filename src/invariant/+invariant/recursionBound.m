% Copyright (c) 2026, SNAPKITTY Research
% Licensed under BSD-3-Clause OR GPL-1.0

function [pass, diagnostic] = recursionBound(recursion_tree, config)
    % I8: Recursion Bound
    % Recursive execution must respect configured maximum depth

    diagnostic = struct();
    diagnostic.invariant = 'I8_RecursionBound';

    % Find maximum depth
    max_depth = 0;
    node_count = 0;
    depth_violations = 0;

    function traverse(node)
        node_count = node_count + 1;
        if node.depth > max_depth
            max_depth = node.depth;
        end
        if node.depth > config.maxRecursionDepth
            depth_violations = depth_violations + 1;
        end

        if isfield(node, 'children') && ~isempty(node.children)
            for i = 1:length(node.children)
                traverse(node.children{i});
            end
        end
    end

    if ~isempty(recursion_tree)
        traverse(recursion_tree);
    end

    pass = (depth_violations == 0) && (node_count <= config.maxTotalNodes);

    diagnostic.maxDepthReached = max_depth;
    diagnostic.configuredMaxDepth = config.maxRecursionDepth;
    diagnostic.totalNodes = node_count;
    diagnostic.configuredMaxNodes = config.maxTotalNodes;
    diagnostic.depthViolations = depth_violations;
    diagnostic.pass = pass;

    if ~pass
        diagnostic.message = sprintf(...
            'Recursion bounds exceeded: depth=%d/%d, nodes=%d/%d', ...
            max_depth, config.maxRecursionDepth, node_count, config.maxTotalNodes);
    end

end
