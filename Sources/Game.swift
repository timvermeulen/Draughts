public struct Game {
    public let startNumber: Int
    
    public var isLocked = false
    
    public fileprivate(set) var moves: PlyArray<Move>
    
    // Both `positions` and `variations` will at all times contain exactly
    // one element more than `moves`, and will therefore never be empty.
    // Hence, the `startPosition`, `endPosition`, `startVariations` and
    // `endVariations` properties are non-optional.
    public fileprivate(set) var positions: PlyArray<Position>
    public fileprivate(set) var variations: PlyArray<OrderedDictionary<Move, Game>>
    
    // swiftlint:disable force_unwrapping
    public var startPosition: Position { return positions.first! }
    public var endPosition: Position { return positions.last! }
    
    internal var startVariations: OrderedDictionary<Move, Game> { return variations.first! }
    internal var endVariations: OrderedDictionary<Move, Game> { return variations.last! }
    // swiftlint:enable force_unwrapping
    
    public var startPly: Ply { return Ply(player: startPosition.playerToMove, number: startNumber) }
    public var endPly: Ply { return Ply(player: endPosition.playerToMove, number: startNumber + moves.count) }
    
    public init(position: Position = .start, startNumber: Int = 0) {
        let ply = Ply(player: position.playerToMove, number: startNumber)
        
        self.startNumber = startNumber
        
        moves = PlyArray(ply: ply)
        positions = PlyArray(ply: ply)
        variations = PlyArray(ply: ply)
        
        positions.append(position)
        variations.append([:])
    }
    
    internal init(startNumber: Int, moves: PlyArray<Move>, positions: PlyArray<Position>, variations: PlyArray<OrderedDictionary<Move, Game>>) {
        self.startNumber = startNumber
        
        self.moves = moves
        self.positions = positions
        self.variations = variations
    }
    
    public mutating func play(_ move: Move) {
        moves.append(move)
        positions.append(move.endPosition)
        variations.append([:])
    }
    
    /// returns:
    /// - game: the variation if one was created (or one already existed), `self` otherwise
    /// - inVariation: `true` is a variation was created, `false` otherwise
    @discardableResult
    public mutating func play(_ move: Move, at ply: Ply) -> (game: Game, inVariation: Bool) {
        assert(positions[ply].moveIsValid(move), "invalid move")
        
        if !isLocked && ply == endPly {
            play(move)
            return (self, false)
        } else if !isLocked && moves[ply] == move {
            return (self, false)
        } else if let variation = variations[ply][move] {
            return (variation, true)
        } else {
            let variation = Game(position: move.endPosition, startNumber: ply.number + 1)
            variations[ply][move] = variation
            return (variation, true)
        }
    }
}

extension Game {
    internal struct Deviation: Equatable {
        internal let ply: Ply
        internal let move: Move
        
        internal static func == (left: Deviation, right: Deviation) -> Bool {
            return left.ply == right.ply && left.move == right.move
        }
    }
    
    internal subscript(deviation: Deviation) -> Game? {
        get {
            return variations[checking: deviation.ply]?[deviation.move]
        }
        set {
            guard variations.indices.contains(deviation.ply) else { return }
            variations[deviation.ply][deviation.move] = newValue
        }
    }
    
    /// Points to a specific (sub)variation of the game.
    public struct VariationIndex {
        internal var deviations: ArraySlice<Deviation>
        
        internal init(_ deviations: ArraySlice<Deviation> = []) {
            self.deviations = deviations
        }
        
        internal var child: (child: VariationIndex, deviation: Deviation)? {
            guard let deviation = deviations.first else { return nil }
            return (VariationIndex(deviations.dropFirst()), deviation)
        }
        
        internal var parent: (parent: VariationIndex, deviation: Deviation)? {
            guard let deviation = deviations.last else { return nil }
            return (VariationIndex(deviations.dropLast()), deviation)
        }
    }
    
    public subscript(index: VariationIndex) -> Game {
        get {
            return index.deviations.reduce(self) { game, pair in
                guard let variation = game.variations[pair.ply][pair.move] else { fatalError("index is invalid") }
                return variation
            }
        }
        set {
            if let (childIndex, deviation) = index.child {
                variations[deviation.ply][deviation.move]?[childIndex] = newValue
            } else {
                self = newValue
            }
        }
    }
    
    /// Points to a specific position of the game, possibly belonging to a (sub)variation.
    public struct PositionIndex {
        internal var variationIndex: VariationIndex
        public var ply: Ply
        
        internal init(variationIndex: VariationIndex = VariationIndex(), ply: Ply) {
            self.variationIndex = variationIndex
            self.ply = ply
        }
        
        internal func isChild(of other: PositionIndex) -> Bool {
            guard ply >= other.ply && variationIndex.deviations.count >= other.variationIndex.deviations.count else { return false }
            return !zip(variationIndex.deviations, other.variationIndex.deviations).contains(where: { $0.0 != $0.1 })
        }
    }
    
    public subscript(index: PositionIndex) -> Position {
        return self[index.variationIndex].positions[index.ply]
    }
    
    internal func parentIndex(of index: PositionIndex) -> PositionIndex? {
        let variation = self[index.variationIndex]
        
        guard index.ply == variation.startPly else {
            return PositionIndex(variationIndex: index.variationIndex, ply: index.ply.predecessor)
        }
        
        guard let variationIndex = index.variationIndex.parent?.parent else { return nil }
        
        return PositionIndex(
            variationIndex: variationIndex,
            ply: index.ply.predecessor
        )
    }
    
    internal var startIndex: PositionIndex { return PositionIndex(variationIndex: Game.VariationIndex(), ply: startPly) }
    
    public func game(from ply: Ply) -> Game {
        return Game(
            startNumber: ply.number,
            moves: moves.suffix(from: ply),
            positions: positions.suffix(from: ply),
            variations: variations.suffix(from: ply)
        )
    }
    
    public func game(from index: PositionIndex) -> Game {
        return self[index.variationIndex].game(from: index.ply)
    }
    
    public func gameToPosition(at index: PositionIndex) -> Game {
        let variations: [Game] = index.variationIndex.deviations.scan(self) { game, deviation in
            guard let variation = game[deviation] else { fatalError("invalid game") }
            return variation
        }
        
        let deviations = index.variationIndex.deviations.lazy.map { ($0.move, $0.ply) }
        
        var game = Game(position: startPosition, startNumber: startNumber)
        
        for (variation, (move, ply)) in zip(variations, deviations) {
            for move in variation.moves[game.endPly..<ply] {
                game.play(move)
            }
            
            game.play(move)
        }
        
        // variations is the result of `scan`, which always returns
        // a non-empty array
        // swiftlint:disable:next force_unwrapping
        let lastVariation = variations.last!
        
        for move in lastVariation.moves[game.endPly..<index.ply] {
            game.play(move)
        }
        
        return game
    }
    
    private mutating func appendGame(_ game: Game) {
        assert(endPosition == game.startPosition, "games do not match")
        
        moves.append(contentsOf: game.moves)
        positions.append(contentsOf: game.positions.dropFirst())
        
        variations.removeLast()
        variations.append(contentsOf: game.variations)
    }
    
    private mutating func removeWithoutReplacement(from ply: Ply) {
        // TODO(swift4): remove `startIndex`
        moves = moves[moves.startIndex..<ply.predecessor]
        positions = positions[moves.startIndex..<ply]
        variations = variations[moves.startIndex..<ply]
    }
    
    /// Deletes the move before the given ply, and all following moves, from the game.
    /// returns: `true` if the game's main variation ends up containing no moves, `false` otherwise
    @discardableResult
    public mutating func remove(from ply: Ply) -> Bool {
        guard ply > startPly else { return true }
        
        removeWithoutReplacement(from: ply)
        
        if let (move, newTail) = variations[ply.predecessor].popFirst() {
            play(move)
            appendGame(newTail)
        }
        
        return false
    }
    
    public func canRemove(from index: PositionIndex) -> Bool {
        return !self[index.variationIndex].isLocked
    }
    
    /// returns: `true` if removal was allowed, `false` otherwise
    @discardableResult
    public mutating func remove(from index: PositionIndex) -> Bool {
        guard canRemove(from: index) else { return false }
        
        if self[index.variationIndex].remove(from: index.ply), let (parentIndex, deviation) = index.variationIndex.parent {
            self[parentIndex].variations[deviation.ply].removeValue(forKey: deviation.move)
        }
        
        return true
    }
    
    public func canPromote(at index: VariationIndex) -> Bool {
        guard let parent = index.parent?.parent else { return false }
        return !self[parent].isLocked
    }
    
    /// returns: `true` if promotion was allowed, `false` otherwise
    @discardableResult
    public mutating func promote(at index: VariationIndex) -> Bool {
        guard canPromote(at: index), let (child, deviation) = index.child else { return false }
        
        guard child.deviations.isEmpty else {
            variations[deviation.ply][deviation.move]?.promote(at: index)
            return true
        }
        
        let newVariationMove = moves[deviation.ply]
        let newVariation = game(from: deviation.ply.successor)
        
        removeWithoutReplacement(from: deviation.ply.successor)
        
        play(deviation.move)
        appendGame(self[index])
        
        variations[deviation.ply][newVariationMove] = newVariation
        self[deviation] = nil
        
        return true
    }
    
    internal func allMoves(startingFrom position: Position) -> Set<Move> {
        let ownMoves = Set(moves.filter { $0.startPosition == position })
        return variations
            .joined()
            .lazy
            .map { $0.value.allMoves(startingFrom: position) }
            .reduce(ownMoves, { $0.union($1) })
        
    }
    
    internal func getEndPositions(allowCrossVariationMoves: Bool) -> Set<Position> {
        let endPositions: Set<Position> = variations
            .joined()
            .lazy
            .map { $0.value.getEndPositions(allowCrossVariationMoves: false) }
            .reduce([endPosition], { $0.union($1) })
        
        guard allowCrossVariationMoves else { return endPositions }
        
        return endPositions.filter { allMoves(startingFrom: $0).isEmpty }
    }
    
    public var isValidTactic: Bool {
        return startPosition.playerToMove == .white && !getEndPositions(allowCrossVariationMoves: true).contains(where: { $0.playerToMove == .white })
    }
}

extension Game: Equatable {
    public static func == (left: Game, right: Game) -> Bool {
        return left.positions == right.positions && left.variations == right.variations
    }
}

extension Game: TextOutputStreamable {
    public func write<Target: TextOutputStream>(to target: inout Target) {
        print(
            startPosition, pdn, endPosition,
            separator: "\n", terminator: "",
            to: &target
        )
    }
}
