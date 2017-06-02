/*
 .--------------------           --------------------
 |  01  02  03  04  05|         |  00  01  02  03  04|
 |06  07  08  09  10  |         |05  06  07  08  09  |10
 |  11  12  13  14  15|       10|  11  12  13  14  15|
 |16  17  18  19  20  |         |16  17  18  19  20  |21
 |  21  22  23  24  25| /---\ 21|  22  23  24  25  26|
 |26  27  28  29  30  | \---/   |27  28  29  30  31  |32
 |  31  32  33  34  35|       32|  33  34  35  36  37|
 |36  37  38  39  40  |         |38  39  40  41  42  |43
 |  41  42  43  44  45|       43|  44  45  46  47  48|
 |46  47  48  49  50  |         |49  50  51  52  53  |
 .--------------------           --------------------
 */

private func valueIsValid(_ value: Int) -> Bool {
    return (0 ... 53).contains(value) && value % 11 != 10
}

public struct Square {
    internal let value: Int
    
    public var humanValue: Int { return (value / 11) * 10 + (value % 11) + 1 }
    
    public init(humanValue value: Int) {
        assert((1 ... 50).contains(value), "\(value) is not a valid square")
        self.init(value: ((value - 1) / 10) * 11 + ((value - 1) % 10))
    }
    
    internal init?(checking value: Int) {
        guard valueIsValid(value) else { return nil }
        self.value = value
    }
    
    internal init(value: Int) {
        assert(valueIsValid(value), "\(value) is not a valid square value")
        self.value = value
    }
    
    public func isOnPromotionRow(of player: Player) -> Bool {
        switch player {
        case .white:
            return value < 5
        case .black:
            return value >= 49
        }
    }
    
    public static let all = (1 ... 50).map(Square.init(humanValue:))
}

extension Square: Equatable {
    public static func == (left: Square, right: Square) -> Bool {
        return left.value == right.value
    }
}

extension Square: Comparable {
    public static func < (left: Square, right: Square) -> Bool {
        return left.value < right.value
    }
}

extension Square: Hashable {
    public var hashValue: Int {
        return value.hashValue
    }
}

extension Square: Strideable {
    public func advanced(by distance: Int) -> Square {
        return Square(humanValue: humanValue + distance)
    }
    
    public func distance(to other: Square) -> Int {
        return other.humanValue - humanValue
    }
}

extension Square {
    public enum Direction {
        public enum Side {
            case front, left, back, right
        }
        
        case topLeft
        case topRight
        case bottomRight
        case bottomLeft
        
        public init(player: Player, pieceDirection: Piece.Direction) {
            switch (player, pieceDirection) {
            case (.white, .left):
                self = .topLeft
            case (.white, .right):
                self = .topRight
            case (.black, .left):
                self = .bottomLeft
            case (.black, .right):
                self = .bottomRight
            }
        }
        
        internal var offset: Int {
            switch self {
            case .topLeft:
                return -6
            case .topRight:
                return -5
            case .bottomRight:
                return 6
            case .bottomLeft:
                return 5
            }
        }
        
        public func turned(to relativeDirection: Side) -> Direction {
            switch (self, relativeDirection) {
            case (.topLeft, .front), (.topRight, .left), (.bottomRight, .back), (.bottomLeft, .right):
                return .topLeft
            case (.topLeft, .right), (.topRight, .front), (.bottomRight, .left), (.bottomLeft, .back):
                return .topRight
            case (.topLeft, .back), (.topRight, .right), (.bottomRight, .front), (.bottomLeft, .left):
                return .bottomRight
            case (.topLeft, .left), (.topRight, .back), (.bottomRight, .right), (.bottomLeft, .front):
                return .bottomLeft
            }
        }
        
        internal var edge: Bitboard {
            switch self {
            case .topLeft:
                return Bitboard.topLeftEdge
            case .topRight:
                return Bitboard.topRightEdge
            case .bottomRight:
                return Bitboard.bottomRightEdge
            case .bottomLeft:
                return Bitboard.bottomLeftEdge
            }
        }
        
        public static let all: [Direction] = [.topLeft, .topRight, .bottomRight, .bottomLeft]
        public static let top: [Direction] = [.topLeft, .topRight]
        public static let bottom: [Direction] = [.bottomRight, .bottomLeft]
    }
}

extension Square {
    public func neighbor(to direction: Direction) -> Square? {
        return Square(checking: value + direction.offset)
    }
    
    public func squares(to direction: Direction) -> [Square] {
        guard let neighbor = neighbor(to: direction) else { return [] }
        return Array(first: neighbor, next: { $0.neighbor(to: direction) })
    }
    
    public func direction(to square: Square) -> Direction? {
        // TODO: improve performance, based on offsets
        return Direction.all.first(where: { squares(to: $0).contains(square) })
    }
    
    // returns nil if the two squares aren't on one line (or are equal), and [] if they are neighbors
    public func squares(before square: Square) -> [Square]? {
        guard let direction = direction(to: square) else { return nil }
        guard let neighbor = neighbor(to: direction) else { fatalError("edge of board reached before destination square") }
        guard neighbor != square else { return [] }

        return Array(first: neighbor, next: { inBetween in
            guard let next = inBetween.neighbor(to: direction) else { fatalError("edge of board reached before destination square") }
            return Optional(next, where: { $0 != square })
        })
    }
}

extension Square: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(humanValue: value)
    }
}

extension Square: CustomStringConvertible {
    public var visual: String {
        return String(describing: Bitboard(square: self))
    }
    
    public var description: String {
        return String(humanValue)
    }
}
