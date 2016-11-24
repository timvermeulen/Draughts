public struct Variation {
    public let startPosition: Position
    internal var moves: [Move]
    internal var positions: [Position]
    
    public var endPosition: Position { return self.positions.last ?? self.startPosition }
    public var startPly: Ply { return self.startPosition.ply }
    public var endPly: Ply { return self.endPosition.ply }
    
    public init(position: Position) {
        self.startPosition = position
        self.moves = []
        self.positions = []
    }
    
    public mutating func play(_ move: Move) {
        assert(self.endPosition.moveIsValid(move))
        
        self.moves.append(move)
        self.positions.append(move.played)
    }
}
