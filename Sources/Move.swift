public final class Move {
    public let piece: Piece
    public let end: Square
    public let captures: [Piece]
    
    fileprivate let position: Position
    
    internal let white, black, kings: Bitboard
    
    public var start: Square { return self.piece.square }
    public var isCapture: Bool { return !self.captures.isEmpty }
    
    public init(from origin: Piece, to destination: Square, over captures: [Piece] = [], position: Position) {
        self.piece = origin
        self.end = destination
        self.captures = captures
        
        self.position = position
        
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
    
    public lazy var played: Position = {
        return Position(
            white: self.white.symmetricDifference(self.position.white),
            black: self.black.symmetricDifference(self.position.black),
            kings: self.kings.symmetricDifference(self.position.kings),
            ply: self.position.ply.successor
        )
    }()
    
    public lazy var allIntermediateSquares: [[Square]] = {
        guard self.piece.kind == .king else {
            return self.anyIntermediateSquares.map { [$0] }
        }
        
        guard let firstCapture = self.captures.first else { return [] }
        guard var direction = self.start.direction(to: firstCapture.square) else { fatalError("invalid move") }
        
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
    }()
    
    public lazy var anyIntermediateSquares: [Square] = {
        guard self.piece.kind == .man else {
            return self.allIntermediateSquares.flatMap { $0.first }
        }
        
        guard let firstCapture = self.captures.first else { return [] }
        guard var direction = self.start.direction(to: firstCapture.square) else { fatalError("invalid move") }
        
        return zip(self.captures, self.captures.dropFirst()).map { from, to in
            guard
                let neighbor = from.square.neighbor(to: direction),
                let newDirection = neighbor.direction(to: to.square)
                else { fatalError("invalid move") }
            
            direction = newDirection
            return neighbor
        }
    }()
    
    public lazy var relevantSquares: [Square] = {
        let intermediateRelevantSquares = self.allIntermediateSquares.joined() + self.captures.map { $0.square }
        return intermediateRelevantSquares + [self.start, self.end]
    }()
    
    public lazy var essentialCaptures: [Square] = {
        let similarMoves = self.position.legalMoves.filter { $0.start == self.start && $0.end == self.end }
        
        func isRelevant(_ capture: Piece) -> Bool {
            return similarMoves.contains(where: { !$0.captures.contains(capture) })
        }
        
        return self.captures.filter(isRelevant).map { $0.square }
    }()
    
    public lazy var unambiguousNotation: String = {
        let essentialCaptures = self.essentialCaptures.sorted()
        guard let lastCapture = essentialCaptures.last else { return self.notation }
        
        let essentialDescription = essentialCaptures.count > 1
            ? "\(essentialCaptures.dropLast().map { String(describing: $0) }.joined()) and \(lastCapture))"
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

extension Move: TextOutputStreamable {
    public var notation: String {
        return "\(start)\(isCapture ? "x" : "-")\(end)"
    }
    
    public func write<Target: TextOutputStream>(to target: inout Target) {
        let position = Position(white: white, black: black, kings: kings)
        print(position, self.notation, separator: "\n", to: &target)
    }
}
