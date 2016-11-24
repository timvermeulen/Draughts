public final class Position {
    internal let white, black, kings, empty: Bitboard
    public let ply: Ply
    
    public lazy var legalMoves: [Move] = {
        return self.moves(of: self.ply.player)
    }()
    
    internal func pieces(of player: Player) -> Bitboard {
        return player == .white ? white : black
    }
    
    internal func pieces(of player: Player, kind: Piece.Kind) -> Bitboard {
        return self.pieces(of: player).intersection(kind == .king ? self.kings : self.kings.inverse)
    }
    
    public subscript(square: Square) -> Piece? {
        let kind: Piece.Kind = kings.contains(square) ? .king : .man
        let player: Player
        
        if white.contains(square) { player = .white }
        else if black.contains(square) { player = .black }
        else { return nil }
        
        return Piece(player: player, kind: kind, square: square)
    }
    
    // MARK: -
    // MARK: Initialising a Position
    
    internal init(white: Bitboard, black: Bitboard, kings: Bitboard = .empty, ply: Ply = Ply()) {
        self.white = white
        self.black = black
        self.kings = kings
        self.empty = white.inverse
            .intersection(black.inverse)
            .intersection(Bitboard.realBoard)
        
        self.ply = ply
    }
    
    public convenience init(pieces: [Piece], ply: Ply = Ply()) {
        let white = Bitboard(squares: pieces.filter { $0.player == .white }.map { $0.square })
        let black = Bitboard(squares: pieces.filter { $0.player == .black }.map { $0.square })
        let kings = Bitboard(squares: pieces.filter { $0.kind == .king }.map { $0.square })
        
        self.init(white: white, black: black, kings: kings, ply: ply)
    }
    
    // MARK: -
    // MARK: Moves
    
    internal func moves(of player: Player) -> [Move] {
        let captures = self.captures(of: player)
        return captures.isEmpty ? self.slidingMoves(of: player) : captures
    }
    
    // MARK: Captures
    
    internal func captures(of square: Square) -> (captures: [Move], amount: Int) {
        guard let piece = self[square] else { return ([], 0) }
        
        var moves: [Move] = []
        
        struct Step {
            let square: Square
            let direction: Square.Direction
            let captures: [Piece]
        }
        
        var steps = Square.Direction.all.map { Step(square: square, direction: $0, captures: []) }
        var maxCapture = 0
        
        switch piece.kind {
        case .man:
            while let step = steps.popLast() {
                guard
                    let victim = step.square.neighbor(to: step.direction),
                    let opponentPiece = self[victim],
                    opponentPiece.player == piece.player.opponent && !step.captures.contains(opponentPiece),
                    let destination = victim.neighbor(to: step.direction),
                    self.squareIsEmpty(destination) || destination == square
                    else { continue }
                
                let captures = step.captures + [opponentPiece]
                let newMove = Move(from: piece, to: destination, over: captures, position: self)
                
                if captures.count > maxCapture {
                    maxCapture = captures.count
                    moves.removeAll()
                }
                
                if captures.count == maxCapture && !moves.contains(newMove) {
                    moves.append(newMove)
                }
                
                for side: Square.Direction.Side in [.front, .left, .right] {
                    steps.append(Step(square: destination, direction: step.direction.turned(to: side), captures: captures))
                }
            }
            
        case .king:
            while let step = steps.popLast() {
                guard
                    let victim = self.firstOccupiedSquare(from: step.square, to: step.direction, ignoring: square),
                    let opponentPiece = self[victim],
                    opponentPiece.player == piece.player.opponent && !step.captures.contains(opponentPiece)
                    else { continue }
                
                let destinations = self.emptySquares(from: victim, to: step.direction, ignoring: square)
                let captures = step.captures + [opponentPiece]
                
                for destination in destinations {
                    let move = Move(from: piece, to: destination, over: captures, position: self)
                    
                    if captures.count > maxCapture {
                        maxCapture = captures.count
                        moves.removeAll()
                    }
                    
                    if captures.count == maxCapture && !moves.contains(move) {
                        moves.append(move)
                    }
                    
                    for side: Square.Direction.Side in [.left, .right] {
                        steps.append(Step(square: destination, direction: step.direction.turned(to: side), captures: captures))
                    }
                }
                
                if let firstDestination = destinations.first {
                    steps.append(Step(square: firstDestination, direction: step.direction, captures: captures))
                }
            }
        }
        
        return (moves, maxCapture)
    }
    
    internal func captures(of player: Player) -> [Move] {
        let captures = self.pieces(of: player).map { self.captures(of: $0) }
        guard let maxCapture = captures.map({ $0.amount }).max() else { return [] }
        let maxCaptures = captures.filter { $0.amount == maxCapture }
        return maxCaptures.flatMap { $0.captures }
    }
    
    // MARK: -
    // MARK: Sliding moves
    
    internal func slidingMoves(of player: Player) -> [Move] {
        return self.slidingManMoves(of: player) + self.slidingKingMoves(of: player)
    }
    
    internal func slidingKingMoves(of square: Square) -> [Move] {
        guard let piece = self[square], piece.kind == .king else { return [] }
        
        return Square.Direction.all.flatMap { direction -> [Move] in
            let emptySquares = self.emptySquares(from: square, to: direction)
            return emptySquares.map { Move(from: piece, to: $0, position: self) }
        }
    }
    
    internal func slidingKingMoves(of player: Player) -> [Move] {
        return self.pieces(of: player).flatMap { self.slidingKingMoves(of: $0) }
    }
    
    internal func slidingManMoves(of player: Player) -> [Move] {
        return self.slidingManMoves(of: player, to: .left) + self.slidingManMoves(of: player, to: .right)
    }
    
    internal func slidingManMoves(of player: Player, to pieceDirection: Piece.Direction) -> [Move] {
        let squares = self.menThatCanSlide(to: pieceDirection, of: player)
        
        return squares.flatMap { square in
            let direction = Square.Direction(player: player, pieceDirection: pieceDirection)
            guard let destination = square.neighbor(to: direction) else { return nil }
            
            return Move(from: Piece(player: player, kind: .man, square: square), to: destination, position: self)
        }
    }
    
    internal func squaresThatCanSlide(to direction: Square.Direction) -> Bitboard {
        return direction.edge.inverse.intersection(self.empty.shift(to: direction.turned(to: .back)))
    }
    
    internal func menThatCanSlide(to direction: Piece.Direction, of player: Player) -> Bitboard {
        let pieces = self.pieces(of: player)
        let squares = self.squaresThatCanSlide(to: Square.Direction(player: player, pieceDirection: direction))
        
        return pieces.intersection(squares)
    }
    
    // MARK: -
    // MARK: Helper functions
    
    internal func firstOccupiedSquare(from square: Square, to direction: Square.Direction, ignoring squareToIgnore: Square? = nil) -> Square? {
        return square.squares(to: direction).first(where: { $0 != squareToIgnore && !self.squareIsEmpty($0) })
    }
    
    internal func squareIsEmpty(_ square: Square) -> Bool {
        return self[square] == nil
    }
    
    internal func emptySquares(from square: Square, to direction: Square.Direction, ignoring squareToIgnore: Square? = nil) -> [Square] {
        guard let neighbor = square.neighbor(to: direction), self.squareIsEmpty(neighbor) else { return [] }
        
        return Array(first: neighbor, next: {
            guard let neighbor = $0.neighbor(to: direction) else { return nil }
            return self.squareIsEmpty(neighbor) ? neighbor : nil
        })
    }
    
    // MARK: -
    // MARK: Static positions
    
    public static var empty: Position {
        return Position(white: .empty, black: .empty, kings: .empty)
    }
    
    public static var beginPosition: Position {
        return Position(
            white: Bitboard(squares: 31 ... 50),
            black: Bitboard(squares: 1 ... 20)
        )
    }
    
    // MARK: -
}

extension Position: Equatable {
    public static func == (left: Position, right: Position) -> Bool {
        return left.white == right.white &&
            left.black == right.black &&
            left.kings == right.kings &&
            left.ply.player == right.ply.player
    }
}

extension Position: TextOutputStreamable {
    public func write<Target: TextOutputStream>(to target: inout Target) {
        let border = " " + String(repeating: "-", count: 21)
        print(border, to: &target)
        
        let grid = [1, 11, 21, 31, 41].map { ($0 ..< $0 + 10).map(Square.init(humanValue:)) }
        
        for squares in grid {
            func addSquare(_ square: Square, onSide: Piece.Direction) {
                let separator: Character
                
                switch (white.contains(square), black.contains(square), kings.contains(square)) {
                case (true, _, true): separator = "O"
                case (true, _, _):    separator = "o"
                case (_, true, true): separator = "X"
                case (_, true, _):    separator = "x"
                default:              separator = "-"
                }
                
                target.write(onSide == .left ? "\(separator)   " : "  \(separator) ")
            }
            
            target.write("| ")
            
            for square in squares[0 ..< 5] {
                addSquare(square, onSide: .right)
            }
            
            target.write("|\n| ")
            
            for square in squares[5 ..< 10] {
                addSquare(square, onSide: .left)
            }
            
            target.write("|\n")
        }
        
        target.write(border)
    }
}
