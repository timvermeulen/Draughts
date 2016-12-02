public struct Game {
    public let startNumber: Int
    
    public var isLocked = false
    
    public fileprivate(set) var moves: PlyArray<Move>
    public fileprivate(set) var positions: PlyArray<Position>
    public fileprivate(set) var variations: PlyArray<OrderedDictionary<Move, Game>>
    
    public var startPosition: Position { return self.positions.first! }
    public var endPosition: Position { return self.positions.last! }

    public var startPly: Ply { return Ply(player: self.startPosition.playerToMove, number: self.startNumber) }
    public var endPly: Ply { return Ply(player: self.endPosition.playerToMove, number: self.startNumber + self.moves.count) }
    
    internal var startVariations: OrderedDictionary<Move, Game> { return self.variations.first! }
    internal var endVariations: OrderedDictionary<Move, Game> { return self.variations.last! }

    public init(position: Position = .start, startNumber: Int = 0) {
        let ply = Ply(player: position.playerToMove, number: startNumber)
        
        self.startNumber = startNumber
        
        self.moves = PlyArray(ply: ply)
        self.positions = PlyArray(ply: ply)
        self.variations = PlyArray(ply: ply)
        
        self.positions.append(position)
        self.variations.append([:])
    }
    
    internal init(startNumber: Int, moves: PlyArray<Move>, positions: PlyArray<Position>, variations: PlyArray<OrderedDictionary<Move, Game>>) {
        self.startNumber = startNumber
        
        self.moves = moves
        self.positions = positions
        self.variations = variations
    }
    
    public mutating func play(_ move: Move) {
        self.moves.append(move)
        self.positions.append(move.endPosition)
        self.variations.append([:])
    }
    
    /// returns:
    /// - game: the variation if one was created (or one already existed), `self` otherwise
    /// - inVariation: `true` is a variation was created, `false` otherwise
    @discardableResult
    public mutating func play(_ move: Move, at ply: Ply) -> (game: Game, inVariation: Bool) {
        assert(self.positions[ply].moveIsValid(move), "invalid move")
        
        if !self.isLocked && ply == self.endPly {
            self.play(move)
            return (self, false)
        } else if !self.isLocked && self.moves[ply] == move {
            return (self, false)
        } else if let variation = self.variations[ply][move] {
            return (variation, true)
        } else {
            let variation = Game(position: move.endPosition, startNumber: ply.number + 1)
            self.variations[ply][move] = variation
            return (variation, true)
        }
    }
}

extension Game {
    internal struct Deviation {
        internal let ply: Ply
        internal let move: Move
    }
    
    internal subscript(deviation: Deviation) -> Game? {
        get {
            return self.variations[checking: deviation.ply]?[deviation.move]
        }
        set {
            guard self.variations.indices.contains(deviation.ply) else { return }
            self.variations[deviation.ply][deviation.move] = newValue
        }
    }
    
    /// Points to a specific (sub)variation of the game.
    public struct Index {
        internal var deviations: ArraySlice<Deviation>
        
        internal init(_ deviations: ArraySlice<Deviation> = []) {
            self.deviations = deviations
        }
        
        internal var child: (child: Index, deviation: Deviation)? {
            guard let deviation = self.deviations.first else { return nil }
            return (Index(self.deviations.dropFirst()), deviation)
        }
        
        internal var parent: (parent: Index, deviation: Deviation)? {
            guard let deviation = self.deviations.last else { return nil }
            return (Index(self.deviations.dropLast()), deviation)
        }
    }
    
    public subscript(index: Index) -> Game {
        get {
            return index.deviations.reduce(self) { game, pair in
                guard let variation = game.variations[pair.ply][pair.move] else { fatalError("index is invalid") }
                return variation
            }
        }
        set {
            if let (childIndex, deviation) = index.child {
                self.variations[deviation.ply][deviation.move]?[childIndex] = newValue
            } else {
                self = newValue
            }
        }
    }
    
    public func game(from ply: Ply) -> Game {
        return Game(
            startNumber: ply.number,
            moves: self.moves.suffix(from: ply),
            positions: self.positions.suffix(from: ply),
            variations: self.variations.suffix(from: ply)
        )
    }
    
    public func game(at index: Index, from ply: Ply) -> Game {
        return self[index].game(from: ply)
    }
    
    /// Deletes the move before the given ply, and all following moves, from the game.
    /// returns: `true` if the game's main variation ends up containing no moves, `false` otherwise
    @discardableResult
    public mutating func delete(from ply: Ply) -> Bool {
        guard ply > self.startPly else { return true }

        self.moves.remove(from: ply.predecessor)
        self.positions.remove(from: ply)
        self.variations.remove(from: ply)
        
        if let (move, newTail) = self.variations[ply.predecessor].popFirst() {
            self.moves.append(move)
            self.moves.append(contentsOf: newTail.moves)
            self.positions.append(contentsOf: newTail.positions)
            self.variations.append(contentsOf: newTail.variations)
        }
        
        return false
    }
    
    public mutating func delete(at index: Index, from ply: Ply) {
        if self[index].delete(from: ply), let (parentIndex, deviation) = index.parent {
            self[parentIndex].variations[deviation.ply].removeValue(forKey: deviation.move)
        }
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
            self.startPosition, self.pdn, self.endPosition,
            separator: "\n", terminator: "",
            to: &target
        )
    }
}
