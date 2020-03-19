// TODO: clean up the lazy vars
public final class Move {
    public let startPiece: Piece
    public let endSquare: Square
    public let captures: [Piece]
    public unowned let startPosition: Position
    
    internal let white, black, kings: Bitboard
    
    public var bitboards: (white: Bitboard, black: Bitboard, kings: Bitboard) {
        return (white, black, kings)
    }
    
    public var isPromotion: Bool {
        return startPiece.kind == .man && endSquare.isOnPromotionRow(of: player)
    }
    
    public var endPiece: Piece {
        let isKing = startPiece.kind == .king || isPromotion
        
        return Piece(
            player: player,
            kind: isKing ? .king : .man,
            square: endSquare
        )
    }
    
    public var player: Player { return startPiece.player }
    public var startSquare: Square { return startPiece.square }
    public var isCapture: Bool { return !captures.isEmpty }
    
    public init(from origin: Piece, to destination: Square, over captures: [Piece] = [], position: Position) {
        startPiece = origin
        endSquare = destination
        startPosition = position
        
        self.captures = captures
        
        let playerBitboard = Bitboard(square: origin.square).symmetricDifference(Bitboard(square: destination))
        let opponentBitboard = captures
            .lazy
            .map { Bitboard(square: $0.square) }
            .reduce(Bitboard.empty) { $0.symmetricDifference($1) }
        
        (white, black) = origin.player == .white
            ? (playerBitboard, opponentBitboard)
            : (opponentBitboard, playerBitboard)
        
        let promotion = startPiece.kind == .man && destination.isOnPromotionRow(of: origin.player) ? Bitboard(square: destination) : .empty
        let capturedKings = Bitboard(squares: captures.lazy.filter { $0.kind == .king }.map { $0.square })
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
        guard self.startPiece.kind == .king else {
            return self.anyIntermediateSquares.map { [$0] }
        }
        
        guard let firstCapture = self.captures.first else { return [] }
        guard var direction = self.startSquare.direction(to: firstCapture.square) else { fatalError("invalid move") }
        
        return zip(self.captures, self.captures.dropFirst()).map {
            let (start, end) = $0
            
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
        guard self.startPiece.kind == .man else {
            return self.allIntermediateSquares.compactMap { $0.first }
        }
        
        guard let firstCapture = self.captures.first else { return [] }
        guard var direction = self.startSquare.direction(to: firstCapture.square) else { fatalError("invalid move") }
        
        return zip(self.captures, self.captures.dropFirst()).map {
            let (start, end) = $0
            
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
        guard self.startPiece.kind == .king else { return self.anyIntermediateSquares + [self.endSquare] }
        
        let squares = [self.startSquare] + self.anyIntermediateSquares + [self.endSquare]
        
        let interveningSquares: [[Square]] = zip(squares, squares.dropFirst()).map {
            let (start, end) = $0
            
            guard let squares = start.squares(before: end) else { fatalError("invalid move") }
            return squares
        }
        
        return interveningSquares.joined() + [self.endSquare]
    }()
    
    public lazy var relevantSquares: [Square] = {
        let intermediateRelevantSquares = self.allIntermediateSquares.joined() + self.captures.lazy.map { $0.square }
        return intermediateRelevantSquares + [self.startSquare, self.endSquare]
    }()
    
    public lazy var essentialCaptures: [Square] = {
        let similarMoves = self.startPosition.legalMoves.filter { $0.startSquare == self.startSquare && $0.endSquare == self.endSquare }
        
        func isRelevant(_ capture: Piece) -> Bool {
            return similarMoves.contains(where: { !$0.captures.contains(capture) })
        }
        
        return self.captures.filter(isRelevant).map { $0.square }
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
    public func hash(into hasher: inout Hasher) {
        hasher.combine(white)
        hasher.combine(black)
        hasher.combine(kings)
    }
}

extension Move: CustomStringConvertible {
    public var unambiguousNotation: String {
        let essentialCaptures = self.essentialCaptures.sorted()
        guard let lastCapture = essentialCaptures.last else { return notation }
        
        let essentialDescription = essentialCaptures.count > 1
            ? essentialCaptures.dropLast().lazy.map { String(describing: $0) }.joined() + " and \(lastCapture)"
            : String(describing: lastCapture)
        
        return "\(notation) (over \(essentialDescription))"
    }
    
    public var notation: String {
        return "\(startSquare)\(isCapture ? "x" : "-")\(endSquare)"
    }
    
    public var description: String {
        return unambiguousNotation
    }
}
