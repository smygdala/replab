function dispatchDefaults
% Register here the default functions used in dispatch for the core of RepLAB

% Equivariant construction
    replab.dispatch('register', 'replab.makeEquivariant', 'ForRepByImages', 10, ...
                    @(repR, repC, special) replab.equivariant.ForRepByImages.make(repR, repC, special));
    replab.dispatch('register', 'replab.makeEquivariant', 'ForFiniteGroup', 5, ...
                    @(repR, repC, special) replab.equivariant.ForFiniteGroup.make(repR, repC, special));
    % Default method, works for all compact groups
    replab.dispatch('register', 'replab.makeEquivariant', 'ForCompactGroup', 0, ...
                    @(repR, repC, special) replab.equivariant.ForCompactGroup.make(repR, repC, special));

    replab.dispatch('register', 'replab.irreducible.decomposition', 'UsingSplit', 0, ...
                    @(rep) replab.irreducible.decompositionUsingSplit(rep));

    replab.dispatch('register', 'replab.irreducible.split', 'ReduceBlocks', 500, ...
                    @(rep, samples, sub) replab.irreducible.splitPermutations(rep, samples, sub));
    replab.dispatch('register', 'replab.irreducible.split', 'UsingCommutant', 0, ...
                    @(rep, samples, sub) replab.irreducible.splitUsingCommutant(rep, samples, sub));

    replab.dispatch('register', 'replab.graph.burningAlgorithm', 'Fast', 500, ...
                    @(edges) replab.graph.burningAlgorithmFast(edges));
    replab.dispatch('register', 'replab.graph.burningAlgorithm', 'Fallback', 0, ...
                    @(edges) replab.graph.burningAlgorithm(edges));
end
