public struct Bitboard {
    public var value: UInt64
    
    public init(_ value: UInt64) {
        self.value = value
    }
    
    public static var empty: Bitboard { return Bitboard(0 as UInt64) }
}

extension Bitboard: Equatable {
    public static func == (left: Bitboard, right: Bitboard) -> Bool {
        return left.value == right.value
    }
}

extension Bitboard: Sequence {
    public func makeIterator() -> BitboardIterator {
        return BitboardIterator(self)
    }
}

extension Bitboard {
    internal init(square: Square) {
        self.value = 1 << UInt64(square.value)
    }
    
    internal init<S: Sequence>(squares: S) where S.Iterator.Element == Square {
        self.value = squares.reduce(0) { $0 ^ Bitboard(square: $1).value }
    }
    
    internal init(squares: Square...) {
        self.init(squares: squares)
    }
    
    public var count: Int {
        return value.nonzeroBitCount
    }
}

extension Bitboard {
    internal static func << (bitboard: Bitboard, int: Int) -> Bitboard {
        guard int >= 0 else { return bitboard >> (-int) }
        return Bitboard(bitboard.value << int)
    }
    
    internal static func >> (bitboard: Bitboard, int: Int) -> Bitboard {
        guard int >= 0 else { return bitboard << (-int) }
        return Bitboard(bitboard.value >> int)
    }
    
    internal func shift(to direction: Square.Direction, count: Int = 1) -> Bitboard {
        return self << (direction.offset * count)
    }
}

extension Bitboard {
    internal static let topEdge: Bitboard = Bitboard(squares: 1 ... 5)
    internal static let bottomEdge: Bitboard = Bitboard(squares: 46 ... 50)
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
