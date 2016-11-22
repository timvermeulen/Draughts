public struct Move {
    public let piece: Piece
    public let destination: Square
    public let over: [Piece]
    
    internal let white, black, kings: Bitboard
    
    public var from: Square { return piece.square }
    public var isCapture: Bool { return !over.isEmpty }
    
    public init(from origin: Piece, to destination: Square, over: [Piece] = []) {
        self.piece = origin
        self.destination = destination
        self.over = over
        
        let playerBitboard = Bitboard(origin.square).symmetricDifference(Bitboard(destination))
        let opponentBitboard = over.reduce(Bitboard.empty) { $0.symmetricDifference(Bitboard($1.square)) }
        
        (white, black) = origin.player == .white
            ? (playerBitboard, opponentBitboard)
            : (opponentBitboard, playerBitboard)
        
        let promotion = piece.kind == .man && destination.isOnPromotionRow(of: origin.player) ? Bitboard(destination) : .empty
        let capturedKings = Bitboard(squares: self.over.filter { $0.kind == .king }.map { $0.square })
        let movedKing = origin.kind == .king ? Bitboard(squares: origin.square, destination) : .empty
        
        kings = promotion
            .symmetricDifference(capturedKings)
            .symmetricDifference(movedKing)
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
        return "\(from.humanValue)\(isCapture ? "x" : "-")\(destination.humanValue)"
    }
    
    public func write<Target: TextOutputStream>(to target: inout Target) {
        let position = Position(white: white, black: black, kings: kings)
        print(position, self.notation, separator: "\n", to: &target)
    }
}
