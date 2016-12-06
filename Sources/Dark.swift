extension Position {
    public var darkPosition: Position {
        let player = self.pieces(of: self.playerToMove)
        let opponent = self.pieces(of: self.playerToMove.opponent)
        
        func position(opponent: Bitboard = .empty) -> Position {
            return Position(
                white: self.playerToMove == .white ? player : opponent,
                black: self.playerToMove == .black ? player : opponent,
                kings: self.kings.intersection(player.union(opponent)),
                playerToMove: self.playerToMove
            )
        }
        
        let positions = Array(first: position()) { candidate in
            let ownMoves = Set(self.legalMoves)
            let candidateMoves = Set(candidate.legalMoves)
            
            guard ownMoves != candidateMoves else { return nil }
            
            let legalMoves = ownMoves.subtracting(candidateMoves)
            let illegalMoves = candidateMoves.subtracting(ownMoves)
            
            let captures = Bitboard(squares: Set(legalMoves.flatMap { $0.captures }).map { $0.square })
            let obstacles = Bitboard(squares: illegalMoves.flatMap { $0.interveningSquares.first(where: opponent.contains) })
            
            return position(opponent: candidate.pieces(of: self.playerToMove.opponent).union(captures).union(obstacles))
        }
        
        return positions.last!
    }
    
    internal func darkPositions(after position: Position?) -> (white: Position, black: Position) {
        let player = self.darkPosition
        let opponent: Position
        
        let darkPosition = position?.darkPosition
        
        let (white, black): (Bitboard, Bitboard) = self.playerToMove == .white
            ? (darkPosition?.white ?? .empty, self.black)
            : (self.white, darkPosition?.black ?? .empty)
        
        opponent = Position(
            white: white,
            black: black,
            kings: self.kings.intersection(white).intersection(black),
            playerToMove: self.playerToMove
        )
        
        return self.playerToMove == .white
            ? (player, opponent)
            : (opponent, player)
    }
}

extension Game {
    func darkPositions(at index: PositionIndex) -> (white: Position, black: Position) {
        let helper = GameHelper(game: self)
        helper.move(to: index)
        
        let position = helper.position
        let previousPosition = Optional(helper.position, where: helper.backward())
        
        return position.darkPositions(after: previousPosition)
    }
}

extension GameHelper {
    public var darkPositions: (white: Position, black: Position) {
        return self.game.darkPositions(at: self.index)
    }
}