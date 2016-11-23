struct Variation {
    let startPosition: Position
    var moves: [(move: Move, position: Position, subvariations: [Variation])]
    
    var endPosition: Position { return self.moves.last?.position ?? self.startPosition }
    var startPly: Ply { return self.startPosition.ply }
    var endPly: Ply { return self.endPosition.ply }
    
    init(position: Position) {
        self.startPosition = position
        self.moves = []
    }
    
    func play(_ move: Move) {
        self.play(move, at: self.endPly)
    }
    
    func play(_ move: Move, at ply: Ply) {
        
    }
}
