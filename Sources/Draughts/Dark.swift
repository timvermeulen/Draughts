extension Position {
    public var darkPosition: Position {
        let player = pieces(of: playerToMove)
        let opponent = pieces(of: playerToMove.opponent)
        
        func position(opponent: Bitboard = .empty) -> Position {
            return Position(
                white: playerToMove == .white ? player : opponent,
                black: playerToMove == .black ? player : opponent,
                kings: kings.intersection(player.union(opponent)),
                playerToMove: playerToMove
            )
        }
        
        let positions = Array(first: position()) { candidate in
            let ownMoves = Set(self.legalMoves)
            let candidateMoves = Set(candidate.legalMoves)
            
            guard ownMoves != candidateMoves else { return nil }
            
            let legalMoves = ownMoves.subtracting(candidateMoves)
            let illegalMoves = candidateMoves.subtracting(ownMoves)
            
            let capturedPieces = Set(legalMoves.flatMap { $0.captures })
            let obstacleSquares = Set(illegalMoves.compactMap { $0.interveningSquares.first(where: opponent.contains) })
            
            let captureBitboard = Bitboard(squares: capturedPieces.lazy.map { $0.square })
            let obstacleBitboard = Bitboard(squares: obstacleSquares)
            
            let opponentBitboard = candidate
                .pieces(of: playerToMove.opponent)
                .union(captureBitboard)
                .union(obstacleBitboard)
            
            return position(opponent: opponentBitboard)
        }
        
        // The Array(first:next:) initialiser always returns a non-empty array, so
        // this `!` is safe.
        // swiftlint:disable:next force_unwrapping
        return positions.last!
    }
    
    internal func darkPositions(after position: Position?) -> (white: Position, black: Position) {
        let player = self.darkPosition
        let opponent: Position
        
        let darkPosition = position?.darkPosition
        
        let (white, black): (Bitboard, Bitboard) = playerToMove == .white
            ? (darkPosition?.white ?? .empty, self.black)
            : (self.white, darkPosition?.black ?? .empty)
        
        opponent = Position(
            white: white,
            black: black,
            kings: kings.intersection(white).intersection(black),
            playerToMove: playerToMove
        )
        
        return playerToMove == .white
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
        return game.darkPositions(at: index)
    }
}
