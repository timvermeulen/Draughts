public struct Position {
    fileprivate var white, black, kings, empty: Bitboard
    public var ply: Ply
    
    internal func pieces(of player: Player) -> Bitboard {
        return player == .white ? white : black
    }
    
    // MARK: -
    // MARK: Initialising a Position
    
    internal init(white: Bitboard, black: Bitboard, kings: Bitboard = .empty, ply: Ply = Ply()) {
        self.white = white
        self.black = black
        self.kings = kings
        self.empty = ~white & ~black & Bitboard.realBoard
        
        self.ply = ply
    }
    
    public init(pieces: [Piece], ply: Ply = Ply()) {
        let white = Bitboard(squares: pieces.filter { $0.player == .white }.map { $0.square })
        let black = Bitboard(squares: pieces.filter { $0.player == .black }.map { $0.square })
        let kings = Bitboard(squares: pieces.filter { $0.kind == .king }.map { $0.square })
        self.init(white: white, black: black, kings: kings, ply: ply)
    }
    
    public subscript(square: Square) -> Piece? {
        let kind: Piece.Kind = kings.contains(square) ? .king : .man
        let player: Player
        switch (white.contains(square), black.contains(square)) {
        case (true, _): player = .white
        case (_, true): player = .black
        default: return nil
        }
        return Piece(player: player, kind: kind, square: square)
    }
    
    // MARK: -
    // MARK: Applying moves
    
    public mutating func play(_ move: Move) {
        white ^= move.white
        black ^= move.black
        kings ^= move.kings
        ply = ply.successor
    }
    
    public func playing(move: Move) -> Position {
        var position = self
        position.play(move)
        return position
    }
    
    // MARK: -
    // MARK: Man moves
    
    public func generateMoves() -> [Move] {
        return self.moves(of: self.ply.player)
    }
    
    internal func moves(of player: Player) -> [Move] {
        let captures = self.captures(of: player)
        return captures.isEmpty ? self.slidingMoves(of: player) : captures
    }
    
    internal func firstOccupiedSquare(from square: Square, to direction: Square.Direction, ignoring squareToIgnore: Square? = nil) -> Square? {
        return square.squares(to: direction).first(where: { $0 != squareToIgnore && !squareIsEmpty($0) })
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
        
        while let step = steps.popLast() {
            let theNeighbor: Square?
            
            switch piece.kind {
            case .man: theNeighbor = step.square.neighbor(to: step.direction)
            case .king: theNeighbor = self.firstOccupiedSquare(from: step.square, to: step.direction, ignoring: square)
            }
            
            guard let neighbor = theNeighbor, let opponentPiece = self[neighbor], opponentPiece.player == piece.player.opponent && !step.captures.contains(opponentPiece) else {
                continue
            }
            
            let endSquares: [Square]
            
            switch piece.kind {
            case .man:
                if let endSquare = neighbor.neighbor(to: step.direction), squareIsEmpty(endSquare) || endSquare == square {
                    endSquares = [endSquare]
                } else {
                    endSquares = []
                }
            case .king: endSquares = self.emptySquares(from: neighbor, to: step.direction, ignoring: square)
            }
            
            let newCaptures = step.captures + [opponentPiece]
            for endSquare in endSquares {
                let newMove = Move(from: piece, to: endSquare, over: newCaptures)
                
                if newCaptures.count > maxCapture {
                    maxCapture = newCaptures.count
                    moves.removeAll()
                }
                
                if newCaptures.count == maxCapture && !moves.contains(newMove) {
                    moves.append(newMove)
                }
                
                var directions = [step.direction.left, step.direction.right]
                
                if endSquares[0] == endSquare {
                    directions.append(step.direction)
                }
                
                for direction in directions {
                    steps.append(Step(square: endSquare, direction: direction, captures: newCaptures))
                }
            }
        }
        
        return (moves, maxCapture)
    }
    
    internal func captures(of player: Player) -> [Move] {
        let captures = self.pieces(of: player).squares.map { self.captures(of: $0) }
        guard let maxCapture = captures.map({ $0.amount }).max() else { return [] }
        let maxCaptures = captures.filter { $0.amount == maxCapture }
        return maxCaptures.flatMap { $0.captures }
    }
    
    internal func slidingMoves(of player: Player) -> [Move] {
        return self.slidingManMoves(of: player) + self.slidingKingMoves(of: player)
    }
    
    internal func slidingKingMoves(of square: Square) -> [Move] {
        guard let piece = self[square], piece.kind == .king else { return [] }
        
        return Square.Direction.all.flatMap { direction -> [Move] in
            let emptySquares = self.emptySquares(from: square, to: direction)
            
            return emptySquares.map { emptySquare in
                Move(from: piece, to: emptySquare)
            }
        }
    }
    
    internal func slidingKingMoves(of player: Player) -> [Move] {
        return self.pieces(of: player).squares.flatMap { self.slidingKingMoves(of: $0) }
    }
    
    internal func slidingManMoves(of player: Player) -> [Move] {
        return slidingManMoves(of: player, to: .left) + slidingManMoves(of: player, to: .right)
    }
    
    internal func slidingManMoves(of player: Player, to pieceDirection: Piece.Direction) -> [Move] {
        let squares = menThatCanSlide(to: pieceDirection, of: player).squares
        
        return squares.map { square in
            let direction = Square.Direction(player: player, pieceDirection: pieceDirection)
            let to = Square(value: square.value + direction.rawValue)
            
            return Move(from: Piece(player: player, kind: .man, square: square), to: to)
        }
    }
    
    internal func squaresThatCanSlide(to direction: Square.Direction) -> Bitboard {
        return ~direction.edge & empty.shift(to: direction.opposite)
    }
    
    internal func menThatCanSlide(to direction: Piece.Direction, of player: Player) -> Bitboard {
        return pieces(of: player) & ~kings & squaresThatCanSlide(to: Square.Direction(player: player, pieceDirection: direction))
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
        
        for squares in [1, 11, 21, 31, 41].map({ ($0 ..< $0 + 10).map(Square.init(humanValue:)) }) {
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
