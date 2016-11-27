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
    
    public mutating func play(_ move: Move) {
        self.play(move, at: self.endPly)
    }
    
    public mutating func play(_ move: Move, at ply: Ply) {
        assert(self.positions[ply].moveIsValid(move))
        
        if ply == self.endPly {
            self.moves.append(move)
            self.positions.append(move.endPosition)
            variations.append([])
        } else {
            if !self.variations[ply].contains(where: { $0.move == move }) {
                self.variations[ply].append((move, Game(position: move.endPosition)))
            }
        }
    }
}
