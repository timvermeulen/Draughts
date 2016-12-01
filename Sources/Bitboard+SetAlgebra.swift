extension Bitboard {
    internal var inverse: Bitboard {
        return Bitboard(~self.value)
    }
}

extension Bitboard: SetAlgebra {
    internal init() {
        self = .empty
    }
    
    internal func contains(_ square: Square) -> Bool {
        return self.value & Bitboard(square: square).value != 0
    }
    
    internal func union(_ other: Bitboard) -> Bitboard {
        return Bitboard(self.value | other.value)
    }
    
    internal func intersection(_ other: Bitboard) -> Bitboard {
        return Bitboard(self.value & other.value)
    }
    
    internal func symmetricDifference(_ other: Bitboard) -> Bitboard {
        return Bitboard(self.value ^ other.value)
    }
    
    internal mutating func formUnion(_ other: Bitboard) {
        self.value |= other.value
    }
    
    internal mutating func formIntersection(_ other: Bitboard) {
        self.value &= other.value
    }
    
    internal mutating func formSymmetricDifference(_ other: Bitboard) {
        self.value ^= other.value
    }
    
    @discardableResult
    internal mutating func insert(_ square: Square) -> (inserted: Bool, memberAfterInsert: Square) {
        let inserted = !self.contains(square)
        self.value |= Bitboard(square: square).value
        return (inserted, square)
    }
    
    @discardableResult
    internal mutating func remove(_ square: Square) -> Square? {
        defer { self.value &= ~Bitboard(square: square).value }
        return Optional(square, where: self.contains)
    }
    
    @discardableResult
    internal mutating func update(with square: Square) -> Square? {
        return Optional(square, where: { self.insert($0).inserted })
    }
}
