public struct Game {
    public let startPosition: Position
    public let startNumber: Int
    
    public var moves: PlyArray<Move>
    public var positions: PlyArray<Position>
    public var variations: PlyArray<[(move: Move, variation: Game)]>
    
    // causes a segfault:
    // public var endPosition: Position { return self.positions.last ?? self.startPosition }

    public var endPosition: Position { return self.positions[self.positions.index(before: self.positions.endIndex)] }
    public var startPly: Ply { return Ply(player: self.startPosition.playerToMove, number: self.startNumber) }
    public var endPly: Ply { return Ply(player: self.endPosition.playerToMove, number: self.startNumber + self.moves.count) }

    public init(position: Position = .start, startNumber: Int = 0) {
        let ply = Ply(player: position.playerToMove, number: startNumber)
        
        self.startPosition = position
        self.startNumber = startNumber
        
        self.moves = PlyArray(ply)
        self.positions = PlyArray(ply)
        self.variations = PlyArray(ply)
        
        self.positions.append(self.startPosition)
    }
    
    public init(move: Move, startNumber: Int = 0) {
        self.init(position: move.startPosition, startNumber: startNumber)
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
                self.variations[ply].append((move, Game(move: move, startNumber: ply.number)))
                return self.variations[ply].count - 1
            }
        }
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
