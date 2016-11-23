public struct Move {
    public let piece: Piece
    public let destination: Square
    public let captures: [Piece]
    
    internal let white, black, kings: Bitboard
    
    public var origin: Square { return self.piece.square }
    public var isCapture: Bool { return !self.captures.isEmpty }
    
    public init(from origin: Piece, to destination: Square, over captures: [Piece] = []) {
        self.piece = origin
        self.destination = destination
        self.captures = captures
        
        let playerBitboard = Bitboard(origin.square).symmetricDifference(Bitboard(destination))
        let opponentBitboard = captures
            .map { Bitboard($0.square) }
            .reduce(Bitboard.empty) { $0.symmetricDifference($1) }
        
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
    var allIntermediateSquares: [[Square]] {
        guard self.piece.kind == .king else {
            return self.anyIntermediateSquares.map { [$0] }
        }
        
        guard let firstCapture = self.captures.first else { return [] }
        guard var direction = self.origin.direction(to: firstCapture.square) else { fatalError("invalid move") }
        
        return zip(self.captures, self.captures.dropFirst()).map { from, to in
            if let squares = from.square.squares(before: to.square) {
                return squares
            } else {
                for square in from.square.squares(to: direction) {
                    guard let newDirection = square.direction(to: to.square) else { continue }
                    
                    direction = newDirection
                    return [square]
                }
                
                fatalError("invalid move")
            }
        }
    }
    
    var anyIntermediateSquares: [Square] {
        guard self.piece.kind == .man else {
            return self.allIntermediateSquares.flatMap { $0.first }
        }
        
        guard let firstCapture = self.captures.first else { return [] }
        guard var direction = self.origin.direction(to: firstCapture.square) else { fatalError("invalid move") }
        
        return zip(self.captures, self.captures.dropFirst()).map { from, to in
            guard
                let neighbor = from.square.neighbor(to: direction),
                let newDirection = neighbor.direction(to: to.square)
                else { fatalError("invalid move") }
            
            direction = newDirection
            return neighbor
        }
    }
    
    var relevantSquares: [Square] {
        return [self.origin, self.destination] + self.allIntermediateSquares.joined()
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
