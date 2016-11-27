public struct Game {
    public let startPosition: Position
    
    public var moves: PlyArray<Move>
    public var positions: PlyArray<Position>
    public var variations: PlyArray<[(move: Move, variation: Game)]>
    
    // causes a segfault:
    // public var endPosition: Position { return self.positions.last ?? self.startPosition }

    public var endPosition: Position { return self.positions[self.positions.index(before: self.positions.endIndex)] }
    public var startPly: Ply { return self.startPosition.ply }
    public var endPly: Ply { return self.endPosition.ply }

    public init(position: Position = .start) {
        self.startPosition = position
        self.moves = PlyArray(position.ply)
        self.positions = PlyArray(position.ply)
        self.variations = PlyArray(position.ply)
        
        self.positions.append(self.startPosition)
    }
    
    public init(move: Move) {
        self.init(position: move.startPosition)
        self.play(move)
    }
    
    public mutating func play(_ move: Move) {
        self.play(move, at: self.endPly)
    }
    
    /// returns: the index of the variation if one was created (or one already existed), nil otherwise
    @discardableResult
    public mutating func play(_ move: Move, at ply: Ply) -> Int? {
        assert(self.positions[ply].moveIsValid(move), "invalid move")
        
        if ply == self.endPly {
            self.moves.append(move)
            self.positions.append(move.endPosition)
            variations.append([])
            return nil
        } else {
            if let index = self.variations[ply].index(where: { $0.move == move }) {
                return index
            } else {
                self.variations[ply].append((move, Game(move: move)))
                return self.variations[ply].count - 1
            }
        }
    }
}
