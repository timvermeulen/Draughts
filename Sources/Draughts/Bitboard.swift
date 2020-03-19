public struct Bitboard {
    public var value: UInt64
    
    public init(_ value: UInt64) {
        self.value = value
    }
    
    public static var empty: Bitboard { return Bitboard(0) }
}

extension Bitboard: Equatable {
    public static func == (left: Bitboard, right: Bitboard) -> Bool {
        return left.value == right.value
    }
}

extension Bitboard: Hashable {}

extension Bitboard {
    public func serialized() -> [Square] {
        return Array(state: value) { (bitboard: inout UInt64) in
            let zeroCount = bitboard.leadingZeroBitCount
            guard zeroCount < 64 else { return nil }
            
            let offset = 63 - zeroCount
            bitboard ^= 1 << offset
            
            return Square(value: offset)
        }
    }
    
    public var opposite: Bitboard {
        return Bitboard(~value)
    }
}

extension Bitboard {
    public init(square: Square) {
        value = 1 << UInt64(square.value)
    }
    
    public init<S: Sequence>(squares: S) where S.Iterator.Element == Square {
        value = squares.reduce(0) { $0 ^ Bitboard(square: $1).value }
    }
    
    public init(squares: Square...) {
        self.init(squares: squares)
    }
    
    public var count: Int {
        return value.nonzeroBitCount
    }
}

extension Bitboard {
    internal static func << (bitboard: Bitboard, int: Int) -> Bitboard {
        return Bitboard(bitboard.value << int)
    }
    
    internal static func >> (bitboard: Bitboard, int: Int) -> Bitboard {
        return Bitboard(bitboard.value >> int)
    }
    
    internal func shift(to direction: Square.Direction, count: Int = 1) -> Bitboard {
        return self << (direction.offset * count)
    }
}

extension Bitboard {
    internal static let topEdge: Bitboard = Bitboard(squares: 1...5)
    internal static let bottomEdge: Bitboard = Bitboard(squares: 46...50)
    internal static let leftEdge: Bitboard = Bitboard(squares: 6, 16, 26, 36, 46)
    internal static let rightEdge: Bitboard = Bitboard(squares: 5, 15, 25, 35, 45)
    
    internal static let topLeftEdge: Bitboard = leftEdge.union(topEdge)
    internal static let topRightEdge: Bitboard = topEdge.union(rightEdge)
    internal static let bottomRightEdge: Bitboard = rightEdge.union(bottomEdge)
    internal static let bottomLeftEdge: Bitboard = bottomEdge.union(leftEdge)
    
    internal static let realBoard: Bitboard = Bitboard(squares: Square.all)
}

extension Bitboard: TextOutputStreamable {
    public func write<Target: TextOutputStream>(to target: inout Target) {
        let position = Position(white: .empty, black: self)
        position.write(to: &target)
    }
}

