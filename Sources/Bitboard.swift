internal struct Bitboard {
    internal var value: UInt64
    
    internal init(_ value: UInt64) {
        self.value = value
    }
    
    internal static var empty: Bitboard { return Bitboard(0 as UInt64) }
}

extension Bitboard: Equatable {
    internal static func == (left: Bitboard, right: Bitboard) -> Bool {
        return left.value == right.value
    }
}

extension Bitboard {
    internal init(_ square: Square) {
        self.value = 1 << UInt64(square.value)
    }
    
    internal init<S: Sequence>(squares: S) where S.Iterator.Element == Square {
        self.value = squares.reduce(0) { $0 ^ Bitboard($1).value }
    }
    
    internal init(squares: Square...) {
        self.init(squares: squares)
    }
    
    internal func contains(_ square: Square) -> Bool {
        return self.value & Bitboard(square).value != 0
    }
    
    internal var squares: [Square] {
        return Square.all.filter(self.contains)
    }
    
    internal var count: Int {
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
        return Bitboard(int >= 0
            ? bitboard.value << UInt64(int)
            : bitboard.value >> UInt64(-int)
        )
    }
    
    internal static func >> (bitboard: Bitboard, int: Int) -> Bitboard {
        return Bitboard(int >= 0
            ? bitboard.value >> UInt64(int)
            : bitboard.value << UInt64(-int)
        )
    }
    
    internal func shift(to direction: Square.Direction, count: Int = 1) -> Bitboard {
        return self << (direction.rawValue * count)
    }
}

extension Bitboard {
    internal static prefix func ~ (bitBoard: Bitboard) -> Bitboard {
        return Bitboard(~bitBoard.value)
    }
    
    internal static func | (left: Bitboard, right: Bitboard) -> Bitboard {
        return Bitboard(left.value | right.value)
    }
    
    internal static func ^ (left: Bitboard, right: Bitboard) -> Bitboard {
        return Bitboard(left.value ^ right.value)
    }
    
    internal static func & (left: Bitboard, right: Bitboard) -> Bitboard {
        return Bitboard(left.value & right.value)
    }
    
    internal static func |= (left: inout Bitboard, right: Bitboard) {
        left.value |= right.value
    }
    
    internal static func ^= (left: inout Bitboard, right: Bitboard) {
        left.value ^= right.value
    }
    
    internal static func &= (left: inout Bitboard, right: Bitboard) {
        left.value &= right.value
    }
}

extension Bitboard {
    internal static let topEdge: Bitboard = Bitboard(squares: 1 ... 5)
    internal static let bottomEdge: Bitboard = Bitboard(squares: 46 ... 50)
    internal static let leftEdge: Bitboard = Bitboard(squares: 6, 16, 26, 36, 46)
    internal static let rightEdge: Bitboard = leftEdge >> 1
    
    internal static let topLeftEdge: Bitboard = leftEdge | topEdge
    internal static let topRightEdge: Bitboard = topEdge | rightEdge
    internal static let bottomRightEdge: Bitboard = rightEdge | bottomEdge
    internal static let bottomLeftEdge: Bitboard = bottomEdge | leftEdge
    
    internal static let realBoard: Bitboard = Bitboard(squares: Square.all)
}

extension Bitboard: TextOutputStreamable {
    internal func write<Target: TextOutputStream>(to target: inout Target) {
        let border = " " + String(repeating: "-", count: 21)
        print("\n\(border)", to: &target)
        
        let grid = [1, 11, 21, 31, 41].map {
            ($0 ..< $0 + 10).map(Square.init(humanValue:))
        }
        
        for squares in grid {
            target.write("| ")
            
            for square in squares[0 ..< 5] {
                target.write(self.contains(square) ? "  x " : "  - ")
            }
            
            target.write("|\n| ")
            
            for square in squares[5 ..< 10] {
                target.write(self.contains(square) ? "x   " : "-   ")
            }
            
            target.write("|\n")
        }
        
        print(border, to: &target)
    }
}
