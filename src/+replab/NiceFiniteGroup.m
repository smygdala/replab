classdef NiceFiniteGroup < replab.FiniteGroup
% A nice finite group is a finite group equipped with an injective homomorphism into a permutation group
%
% The class that subclasses `.NiceFiniteGroup` implements a method `.niceMonomorphismImage` that returns a
% permutation row vector corresponding to a group element.
%
% In turn, the `.NiceFiniteGroup` infrastructure will use that method to build a BSGS chain to describe
% the structure of the finite group; this chain also provides a way to compute the preimage of a permutation.
%
% Thus, an isomorphism is established between the present `.NiceFiniteGroup` and a permutation group; as
% permutation groups can be handled by efficient BSGS algorithms, the requested computations can be
% translated back and forth between this group and a permutation group.
%
% In particular, the decomposition of the finite group in a product of sets (`.FiniteGroupDecomposition`),
% the enumeration of elements using a `.IndexedFamily`, the construction of subgroups is all handled
% by permutation group algorithms.
%
% Handling subgroups
%
% Each nice finite group has a parent object, that describes the most general group embedding
% elements of a particular type. For example, permutations of domain size ``n`` are embedded in the
% symmetric group of degree ``n`` (for such groups, their nice monomorphism is the identity).
%
% If this group is its own parent, the methods that are delegated to the parent group
% (including `.eqv`/`compose`/`inverse`) needs to be overriden, otherwise call to their
% methods will end up recursing to the infinity.

    properties (SetAccess = protected)
        parent % `+replab.NiceFiniteGroup`: Parent nice finite group
    end


    properties (Access = protected)
        chain_ % `+replab.+bsgs.Chain`: BSGS chain describing this group
    end

    methods

        function sub = subgroup(self, generators, order)
        % Constructs a subgroup of the current group from generators
        %
        % Args:
        %   generators (row cell array of elements of this group): List of generators
        %   order (vpi, optional): Subgroup order
        %
        % Returns:
        %   `+replab.NiceFiniteSubgroup`: The subgroup generated by `.generators`
            if nargin < 3
                order = [];
            end
            if self.parent == self
                sub = replab.NiceFiniteSubgroup(self, generators, order);
            else
                sub = self.parent.subgroup(generators, order);
            end
        end

        function conj = leftConjugateGroup(self, by)
        % Returns the left conjugate of the current group by the given element
        %
        % ``res = self.leftConjugateGroup(by)``
        %
        % In particular, it ensures that
        % ``res.generator(i) = self.parent.leftConjugate(by, self.generator(i))``
        %
        % Args:
        %   by (element of `parent`): Element to conjugate the group with
        %
        % Returns:
        %   `+replab.NiceFiniteGroup`: The conjugated group
            newGenerators = cellfun(@(g) self.leftConjugate(by, g), self.generators, 'uniform', 0);
            newOrder = self.order;
            conj = self.parent.subgroup(newGenerators, newOrder);
        end

        function grp = trivialSubgroup(self)
        % Returns the trivial subgroup of this group
        %
        % Returns:
        %   `+replab.NiceFiniteGroup`: The trivial subgroup
            grp = self.subgroup({}, vpi(1));
        end

        function g = niceMonomorphismPreimage(self, p)
        % Returns the group element corresponding to a permutation
        %
        % See also `.niceMonomorphismImage`
        %
        % Args:
        %   p (permutation): Permutation representation
        %
        % Returns:
        %   g (element): Group element corresponding to the permutation
            g = self.chain.image(p);
        end

        function p = niceMonomorphismImage(self, g)
        % Returns a permutation representation of the given group element
        %
        % A nice monomorphism is the GAP System terminology for injective
        % homomorphism into a permutation group.
        %
        % Args:
        %   g (element): Group element to represent as a permutation
        %
        % Returns:
        %   permutation: Permutation representation of ``g``
            p = self.parent.niceMonomorphismImage(g);
        end

        %% Domain methods

        function b = eqv(self, x, y)
            b = self.parent.eqv(x, y);
        end

        %% Monoid methods

        function z = compose(self, x, y)
            z = self.parent.compose(x, y);
        end

        %% Group methods

        function xInv = inverse(self, x)
            xInv = self.parent.inverse(x);
        end

        %% CompactGroup methods

        function g = sampleUniformly(self)
            [~, g] = self.chain.sampleUniformlyWithImage;
        end

    end

    methods (Access = protected)

        %% FiniteGroup methods

        function order = computeOrder(self)
            order = self.chain.order;
        end

        function chain = computeChain(self)
            imgId = self.niceMonomorphismImage(self.identity);
            n = length(imgId);
            nG = self.nGenerators;
            S = zeros(n, nG);
            for i = 1:nG
                S(:,i) = self.niceMonomorphismImage(self.generator(i));
            end
            chain = replab.bsgs.Chain.makeWithImages(n, S, self, self.generators);
        end

        function E = computeElements(self)
            E = replab.IndexedFamily.lambda(self.order, ...
                                            @(ind) self.chain.imageFromIndex(ind), ...
                                            @(el) self.chain.indexFromElement(self.niceMonomorphismImage(el)));
        end

        function dec = computeDecomposition(self)
            dec = replab.FiniteGroupDecomposition(self, self.chain.imagesDecomposition);
        end

    end

    methods

        function o = elementOrder(self, g)
        % Returns the order of a group element
        %
        % Args:
        %   g (element): Group element
        %
        % Returns:
        %   integer: The order of ``g``, i.e. the smallest ``o`` such that ``g^o == identity``
            p = self.niceMonomorphismImage(g);
            orbits = replab.Partition.permutationsOrbits(p);
            orders = unique(orbits.blockSizes);
            o = 1;
            for i = 1:length(orders)
                o = lcm(o, orders(i));
            end
        end

        function c = chain(self)
        % Returns the BSGS chain corresponding to this group
        %
        % Returns:
        %   `+replab.+bsgs.Chain`: BSGS chain describing this group
            if isempty(self.chain_)
                self.chain_ = self.computeChain;
            end
            c = self.chain_;
        end

        %% Methods enabled by the BSGS algorithms

        function b = contains(self, g)
        % Tests whether this group contains the given parent group element
        %
        % Abstract in `+replab.NiceFiniteSubgroup`
        %
        % Args:
        %   g (element of `parent`): Element to test membership of
        %
        % Returns:
        %   logical: True if this group contains ``g`` and false otherwise
            b = self.chain.contains(self.niceMonomorphismImage(g));
        end

        %% Representation construction

        function rho = repByImages(self, field, dimension, images, inverseImages)
        % Constructs a finite dimensional representation of this group from generator images
        %
        % Args:
        %   field ({'R', 'C'}): Whether the representation is real (R) or complex (C)
        %   dimension (integer): Representation dimension
        %   images (cell(1,\*) of double(\*,\*), may be sparse): Images of the group generators
        %   inverseImages (cell(1,\*) of double(\*,\*), may be sparse): Inverse images of the group generators
        % Returns:
        %   `+replab.Rep`: The constructed group representation
            rho = replab.RepByImages(self, field, dimension, images, inverseImages);
        end

        function rho = permutationRep(self, dimension, permutations)
        % Constructs a permutation representation of this group
        %
        % The returned representation is real. Use ``rep.complexification`` to obtain a complex representation.
        %
        % Args:
        %   dimension (integer): Dimension of the representation
        %   permutations (cell(1,\*) of permutations): Images of the generators as permutations of size ``dimension``
        %
        % Returns:
        %   `+replab.Rep`: The constructed group representation
            S = replab.Permutations(dimension);
            f = @(g) S.toSparseMatrix(g);
            images = cellfun(f, permutations, 'uniform', 0);
            inverseImages = cellfun(@(i) i', images, 'uniform', 0);
            rho = self.repByImages('R', dimension, images, inverseImages);
        end

        function rho = signedPermutationRep(self, dimension, signedPermutations)
        % Returns a real signed permutation representation of this group
        %
        % The returned representation is real. Use ``rep.complexification`` to obtain a complex representation.
        %
        % Args:
        %   dimension: Dimension of the representation
        %   signedPermutations (row cell array of signed permutations): Images of the generators as signed permutations of size ``dimension``
        %
        % Returns:
        %   `+replab.Rep`: The constructed group representation
            f = @(g) replab.signed.Permutations.toSparseMatrix(g);
            images = cellfun(f, signedPermutations, 'uniform', 0);
            inverseImages = cellfun(@(i) i', images, 'uniform', 0);
            rho = self.repByImages('R', dimension, images, inverseImages);
        end

    end

end
