public final class Move {
    public let piece: Piece
    public let endSquare: Square
    public let captures: [Piece]
    public let startPosition: Position
    
    internal let white, black, kings: Bitboard
    
    public var bitboards: (white: UInt64, black: UInt64, kings: UInt64) {
        return (self.white.value, self.black.value, self.kings.value)
    }
    
    public var startSquare: Square { return self.piece.square }
    public var isCapture: Bool { return !self.captures.isEmpty }
    
    public init(from origin: Piece, to destination: Square, over captures: [Piece] = [], position: Position) {
        self.piece = origin
        self.endSquare = destination
        self.captures = captures
        
        self.startPosition = position
        
        let playerBitboard = Bitboard(square: origin.square).symmetricDifference(Bitboard(square: destination))
        let opponentBitboard = captures
            .map { Bitboard(square: $0.square) }
            .reduce(Bitboard.empty) { $0.symmetricDifference($1) }
        
        (white, black) = origin.player == .white
            ? (playerBitboard, opponentBitboard)
            : (opponentBitboard, playerBitboard)
        
        let promotion = piece.kind == .man && destination.isOnPromotionRow(of: origin.player) ? Bitboard(square: destination) : .empty
        let capturedKings = Bitboard(squares: self.captures.filter { $0.kind == .king }.map { $0.square })
        let movedKing = origin.kind == .king ? Bitboard(squares: origin.square, destination) : .empty
        
        kings = promotion
            .symmetricDifference(capturedKings)
            .symmetricDifference(movedKing)
    }
    
    public lazy var endPosition: Position = {
        return Position(
            white: self.white.symmetricDifference(self.startPosition.white),
            black: self.black.symmetricDifference(self.startPosition.black),
            kings: self.kings.symmetricDifference(self.startPosition.kings),
            playerToMove: self.startPosition.playerToMove.opponent
        )
    }()
    
    public lazy var allIntermediateSquares: [[Square]] = {
        guard self.piece.kind == .king else {
            return self.anyIntermediateSquares.map { [$0] }
        }
        
        guard let firstCapture = self.captures.first else { return [] }
        guard var direction = self.startSquare.direction(to: firstCapture.square) else { fatalError("invalid move") }
        
        return zip(self.captures, self.captures.dropFirst()).map { start, end in
            if let squares = start.square.squares(before: end.square) {
                return squares
            } else {
                for square in start.square.squares(to: direction) {
                    guard let newDirection = square.direction(to: end.square) else { continue }
                    
                    direction = newDirection
                    return [square]
                }
                
                fatalError("invalid move")
            }
        }
    }()
    
    public lazy var anyIntermediateSquares: [Square] = {
        guard self.piece.kind == .man else {
            return self.allIntermediateSquares.flatMap { $0.first }
        }
        
        guard let firstCapture = self.captures.first else { return [] }
        guard var direction = self.startSquare.direction(to: firstCapture.square) else { fatalError("invalid move") }
        
        return zip(self.captures, self.captures.dropFirst()).map { start, end in
            guard
                let neighbor = start.square.neighbor(to: direction),
                let newDirection = neighbor.direction(to: end.square)
                else { fatalError("invalid move") }
            
            direction = newDirection
            return neighbor
        }
    }()
    
    /// The squares that are required to be empty for this move to be legal
    public lazy var interveningSquares: [Square] = {
        guard self.piece.kind == .king else { return self.anyIntermediateSquares + [self.endSquare] }
        
        let squares = [self.startSquare] + self.anyIntermediateSquares + [self.endSquare]
        
        let interveningSquares: [[Square]] = zip(squares, squares.dropFirst()).map { start, end in
            guard let squares = start.squares(before: end) else { fatalError("invalid move") }
            return squares
        }
        
        return interveningSquares.joined() + [self.endSquare]
    }()
    
    public lazy var relevantSquares: [Square] = {
        let intermediateRelevantSquares = self.allIntermediateSquares.joined() + self.captures.map { $0.square }
        return intermediateRelevantSquares + [self.startSquare, self.endSquare]
    }()
    
    public lazy var essentialCaptures: [Square] = {
        let similarMoves = self.startPosition.legalMoves.filter { $0.startSquare == self.startSquare && $0.endSquare == self.endSquare }
        
        func isRelevant(_ capture: Piece) -> Bool {
            return similarMoves.contains(where: { !$0.captures.contains(capture) })
        }
        
        return self.captures.filter(isRelevant).map { $0.square }
    }()
    
    public lazy var unambiguousNotation: String = {
        let essentialCaptures = self.essentialCaptures.sorted()
        guard let lastCapture = essentialCaptures.last else { return self.notation }
        
        let essentialDescription = essentialCaptures.count > 1
            ? "\(essentialCaptures.dropLast().map { String(describing: $0) }.joined()) and \(lastCapture)"
            : String(describing: lastCapture)
        
        return "\(self.notation) (over \(essentialDescription))"
    }()
}

extension Move: Equatable {
    public static func == (left: Move, right: Move) -> Bool {
        return left.white == right.white &&
            left.black == right.black &&
            left.kings == right.kings
    }
}

extension Move: Hashable {
    public var hashValue: Int {
        return self.piece.hashValue ^ self.endSquare.hashValue ^ self.captures.map { $0.hashValue }.reduce(0, ^)
    }
}

extension Move: CustomStringConvertible {
    public var notation: String {
        return "\(self.startSquare)\(self.isCapture ? "x" : "-")\(self.endSquare)"
    }
    
    public var description: String {
        return self.unambiguousNotation
    }
}
