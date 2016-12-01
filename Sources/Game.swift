public struct Game {
    public let startPosition: Position
    public let startNumber: Int
    
    public var moves: PlyArray<Move>
    public var positions: PlyArray<Position>
    public var variations: PlyArray<OrderedDictionary<Move, Game>>
    
    // causes a segfault:
    // public var endPosition: Position { return self.positions.last ?? self.startPosition }

    public var endPosition: Position { return self.positions[self.positions.index(before: self.positions.endIndex)] }
    public var startPly: Ply { return Ply(player: self.startPosition.playerToMove, number: self.startNumber) }
    public var endPly: Ply { return Ply(player: self.endPosition.playerToMove, number: self.startNumber + self.moves.count) }

    public init(position: Position = .start, startNumber: Int = 0) {
        let ply = Ply(player: position.playerToMove, number: startNumber)
        
        self.startPosition = position
        self.startNumber = startNumber
        
        self.moves = PlyArray(ply: ply)
        self.positions = PlyArray(ply: ply)
        self.variations = PlyArray(ply: ply)
        
        self.positions.append(self.startPosition)
    }
    
    public init(move: Move, startNumber: Int = 0) {
        self.init(position: move.startPosition, startNumber: startNumber)
        self.play(move)
    }
    
    internal init(position: Position, startNumber: Int, moves: PlyArray<Move>, positions: PlyArray<Position>, variations: PlyArray<OrderedDictionary<Move, Game>>) {
        self.startPosition = position
        self.startNumber = startNumber
        
        self.moves = moves
        self.positions = positions
        self.variations = variations
    }
    
    public mutating func play(_ move: Move) {
        self.play(move, at: self.endPly)
    }
    
    /// returns:
    /// - game: the variation if one was created (or one already existed), `self` otherwise
    /// - inVariation: `true` is a variation was created, `false` otherwise
    @discardableResult
    public mutating func play(_ move: Move, at ply: Ply) -> (game: Game, inVariation: Bool) {
        assert(self.positions[ply].moveIsValid(move), "invalid move")
        
        if ply == self.endPly {
            self.moves.append(move)
            self.positions.append(move.endPosition)
            variations.append([:])
            return (self, false)
        } else {
            if let variation = self.variations[ply][move] {
                return (variation, true)
            } else {
                let variation = Game(move: move, startNumber: ply.number)
                self.variations[ply][move] = variation
                return (variation, true)
            }
        }
    }
}

extension Game {
    internal struct Deviation {
        let ply: Ply
        let move: Move
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
            if let deviation = index.deviations.first {
                let newIndex = Index(index.deviations.dropFirst())
                self.variations[deviation.ply][deviation.move]?[newIndex] = newValue
            } else {
                self = newValue
            }
        }
    }
    
    public func game(from ply: Ply) -> Game {
        return Game(
            position: self.positions[ply],
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
        
        if let (_, newTail) = self.variations[ply.predecessor].popFirst() {
            self.moves.append(contentsOf: newTail.moves)
            self.positions.append(contentsOf: newTail.positions.dropFirst())
            self.variations.append(contentsOf: newTail.variations.dropFirst())
            
            return false
        } else {
            self.variations.removeLast()
            return ply.predecessor == self.startPly
        }
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
