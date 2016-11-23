/*
 .--------------------          --------------------
 |  01  02  03  04  05|        |  00  01  02  03  04|
 |06  07  08  09  10  |        |05  06  07  08  09  |10
 |  11  12  13  14  15|      10|  11  12  13  14  15|
 |16  17  18  19  20  |        |16  17  18  19  20  |21
 |  21  22  23  24  25| ---\ 21|  22  23  24  25  26|
 |26  27  28  29  30  | ---/   |27  28  29  30  31  |32
 |  31  32  33  34  35|      32|  33  34  35  36  37|
 |36  37  38  39  40  |        |38  39  40  41  42  |43
 |  41  42  43  44  45|      43|  44  45  46  47  48|
 |46  47  48  49  50  |        |49  50  51  52  53  |
 .--------------------          --------------------
 */

public struct Square {
    internal let value: Int
    
    var humanValue: Int { return (value / 11) * 10 + (value % 11) + 1 }
    
    init(humanValue value: Int) {
        assert((1 ... 50).contains(value), "\(value) is not a valid square")
        self.init(value: ((value - 1) / 10) * 11 + ((value - 1) % 10))
    }
    
    init?(checking value: Int) {
        guard (0 ... 53).contains(value) && value % 11 != 10 else { return nil }
        self.value = value
    }
    
    init(value: Int) {
        guard let square = Square(checking: value) else { fatalError("\(value) is not a valid square value") }
        self = square
    }
    
    func isOnPromotionRow(of player: Player) -> Bool {
        switch player {
        case .white: return value < 5
        case .black: return value >= 49
        }
    }
    
    static let all = (1 ... 50).map(Square.init(humanValue:))
}

extension Square: Comparable {
    public static func == (left: Square, right: Square) -> Bool {
        return left.value == right.value
    }
    
    public static func < (left: Square, right: Square) -> Bool {
        return left.value < right.value
    }
}

extension Square: Strideable {
    public func advanced(by n: Int) -> Square {
        return Square(humanValue: self.humanValue + n)
    }
    
    public func distance(to other: Square) -> Int {
        return other.humanValue - self.humanValue
    }
}

extension Square {
    public enum Direction: Int {
        case topLeft = -6
        case topRight = -5
        case bottomRight = 6
        case bottomLeft = 5
        
        public init(player: Player, pieceDirection: Piece.Direction) {
            switch (player, pieceDirection) {
            case (.white, .left): self = .topLeft
            case (.white, .right): self = .topRight
            case (.black, .left): self = .bottomLeft
            case (.black, .right): self = .bottomRight
            }
        }
        
        public var left: Direction {
            switch self {
            case .topLeft: return .bottomLeft
            case .topRight: return .topLeft
            case .bottomRight: return .topRight
            case .bottomLeft: return .bottomRight
            }
        }
        
        public var right: Direction {
            switch self {
            case .topLeft: return .topRight
            case .topRight: return .bottomRight
            case .bottomRight: return .bottomLeft
            case .bottomLeft: return .topLeft
            }
        }
        
        public var inverse: Direction {
            switch self {
            case .topLeft: return .bottomRight
            case .topRight: return .bottomLeft
            case .bottomRight: return .topLeft
            case .bottomLeft: return .topRight
            }
        }
        
        public var next: [Direction] {
            switch self {
            case .bottomRight: return [.topRight, .bottomRight, .bottomLeft]
            case .bottomLeft: return [.bottomRight, .bottomLeft, .topLeft]
            case .topLeft: return [.bottomLeft, .topLeft, .topRight]
            case .topRight: return [.topLeft, .topRight, .bottomRight]
            }
        }
        
        internal var edge: Bitboard {
            switch self {
            case .topLeft: return Bitboard.topLeftEdge
            case .topRight: return Bitboard.topRightEdge
            case .bottomRight: return Bitboard.bottomRightEdge
            case .bottomLeft: return Bitboard.bottomLeftEdge
            }
        }
        
        public static var all: [Direction] = [.topLeft, .topRight, .bottomRight, .bottomLeft]
        public static var top: [Direction] = [.topLeft, .topRight]
        public static var bottom: [Direction] = [.bottomRight, .bottomLeft]
    }
}

extension Square {
    public func neighbor(to direction: Direction) -> Square? {
        return Square(checking: self.value + direction.rawValue)
    }
    
    public func squares(to direction: Direction) -> [Square] {
        guard let neighbor = self.neighbor(to: direction) else { return [] }
        return Array(first: neighbor, next: { $0.neighbor(to: direction) })
    }
    
    public func direction(to square: Square) -> Direction? {
        // TODO: improve performance
        return Direction.all.first(where: { self.squares(to: $0).contains(square) })
    }
}

extension Square: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(humanValue: value)
    }
}

extension Square: CustomStringConvertible {
    public var visual: String {
        return String(describing: Bitboard(self))
    }
    
    public var description: String {
        return String(self.humanValue)
    }
}
