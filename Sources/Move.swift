public struct Move {
    public let piece: Piece
    public let destination: Square
    public let captures: [Piece]
    
    internal let white, black, kings: Bitboard
    
    public var origin: Square { return piece.square }
    public var isCapture: Bool { return !captures.isEmpty }
    
    public init(from origin: Piece, to destination: Square, over: [Piece] = []) {
        self.piece = origin
        self.destination = destination
        self.captures = over
        
        let playerBitboard = Bitboard(origin.square).symmetricDifference(Bitboard(destination))
        let opponentBitboard = over.reduce(Bitboard.empty) { $0.symmetricDifference(Bitboard($1.square)) }
        
        (white, black) = origin.player == .white
            ? (playerBitboard, opponentBitboard)
            : (opponentBitboard, playerBitboard)
        
        let promotion = piece.kind == .man && destination.isOnPromotionRow(of: origin.player) ? Bitboard(destination) : .empty
        let capturedKings = Bitboard(squares: self.captures.filter { $0.kind == .king }.map { $0.square })
        let movedKing = origin.kind == .king ? Bitboard(squares: origin.square, destination) : .empty
        
        kings = promotion
            .symmetricDifference(capturedKings)
            .symmetricDifference(movedKing)
    }
}

extension Move {
    var intermediateSquares: [Square] {
        guard self.piece.kind == .man else { fatalError() }

        guard let firstCapture = self.captures.first else { return [] }
        guard var direction = self.origin.direction(to: firstCapture.square) else { fatalError("invalid move") }

        var intermediates: [Square] = []
        
        for (from, to) in zip(self.captures, self.captures.dropFirst()) {
            guard
                let neighbor = from.square.neighbor(to: direction),
                let newDirection = neighbor.direction(to: to.square)
                else { fatalError("invalid move") }
            
            intermediates.append(neighbor)
            direction = newDirection
        }
        
        return intermediates
    }
}

extension Move: Equatable {
    public static func == (left: Move, right: Move) -> Bool {
        return left.white == right.white &&
            left.black == right.black &&
            left.kings == right.kings
    }
}

extension Move: TextOutputStreamable {
    public var notation: String {
        return "\(origin)\(isCapture ? "x" : "-")\(destination)"
    }
    
    public func write<Target: TextOutputStream>(to target: inout Target) {
        let position = Position(white: white, black: black, kings: kings)
        print(position, self.notation, separator: "\n", to: &target)
    }
}
