// TODO: clean up the lazy vars
public final class Move {
    public let startPiece: Piece
    public let endSquare: Square
    public let captures: [Piece]
    public let startPosition: Position
    
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
            white: white.symmetricDifference(startPosition.white),
            black: black.symmetricDifference(startPosition.black),
            kings: kings.symmetricDifference(startPosition.kings),
            playerToMove: startPosition.playerToMove.opponent
        )
    }()
    
    public lazy var allIntermediateSquares: [[Square]] = {
        guard startPiece.kind == .king else {
            return anyIntermediateSquares.map { [$0] }
        }
        
        guard let firstCapture = captures.first else { return [] }
        guard var direction = startSquare.direction(to: firstCapture.square) else { fatalError("invalid move") }
        
        return zip(captures, captures.dropFirst()).map {
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
        guard startPiece.kind == .man else {
            return allIntermediateSquares.flatMap { $0.first }
        }
        
        guard let firstCapture = captures.first else { return [] }
        guard var direction = startSquare.direction(to: firstCapture.square) else { fatalError("invalid move") }
        
        return zip(captures, captures.dropFirst()).map {
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
        guard startPiece.kind == .king else { return anyIntermediateSquares + [endSquare] }
        
        let squares = [startSquare] + anyIntermediateSquares + [endSquare]
        
        let interveningSquares: [[Square]] = zip(squares, squares.dropFirst()).lazy.map {
            let (start, end) = $0
            
            guard let squares = start.squares(before: end) else { fatalError("invalid move") }
            return squares
        }
        
        return interveningSquares.joined() + [endSquare]
    }()
    
    public lazy var relevantSquares: [Square] = {
        let intermediateRelevantSquares = allIntermediateSquares.joined() + captures.lazy.map { $0.square }
        return intermediateRelevantSquares + [startSquare, endSquare]
    }()
    
    public lazy var essentialCaptures: [Square] = {
        let similarMoves = startPosition.legalMoves.filter { $0.startSquare == startSquare && $0.endSquare == endSquare }
        
        func isRelevant(_ capture: Piece) -> Bool {
            return similarMoves.contains(where: { !$0.captures.contains(capture) })
        }
        
        return captures.filter(isRelevant).map { $0.square }
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
        return startPiece.hashValue ^ endSquare.hashValue ^ captures.lazy.map { $0.hashValue }.reduce(0, ^)
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
