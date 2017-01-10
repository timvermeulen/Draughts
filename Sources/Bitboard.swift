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
        let b0 = (self.value >> 0) & 0x5555555555555555
        let b1 = (self.value >> 1) & 0x5555555555555555
        let c = b0 + b1
        let d0 = (c >> 0) & 0x3333333333333333
        let d2 = (c >> 2) & 0x3333333333333333
        let e = d0 + d2
        let f0 = (e >> 0) & 0x0f0f0f0f0f0f0f0f
        let f4 = (e >> 4) & 0x0f0f0f0f0f0f0f0f
        let g = f0 + f4
        let h0 = (g >> 0) & 0x00ff00ff00ff00ff
        let h8 = (g >> 8) & 0x00ff00ff00ff00ff
        let i = h0 + h8
        let j00 = (i >> 00) & 0x0000ffff0000ffff
        let j16 = (i >> 16) & 0x0000ffff0000ffff
        let k = j00 + j16
        let l00 = (k >> 00) & 0x00000000ffffffff
        let l32 = (k >> 32) & 0x00000000ffffffff
        return Int(l00 + l32)
    }
}

extension Bitboard {
    internal static func << (bitboard: Bitboard, int: Int) -> Bitboard {
        guard int >= 0 else { return bitboard >> (-int) }
        return Bitboard(bitboard.value << numericCast(int))
    }
    
    internal static func >> (bitboard: Bitboard, int: Int) -> Bitboard {
        guard int >= 0 else { return bitboard << (-int) }
        return Bitboard(bitboard.value >> numericCast(int))
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
