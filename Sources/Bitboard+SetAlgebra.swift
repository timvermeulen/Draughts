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
        return self.value & Bitboard(square).value != 0
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
    
    internal mutating func insert(_ square: Square) -> (inserted: Bool, memberAfterInsert: Square) {
        let inserted = !self.contains(square)
        self.value |= Bitboard(square).value
        return (inserted, square)
    }
    
    internal mutating func remove(_ square: Square) -> Square? {
        let contained = self.contains(square)
        self.value &= ~Bitboard(square).value
        return contained ? square : nil
    }
    
    internal mutating func update(with square: Square) -> Square? {
        return self.insert(square).inserted ? square : nil
    }
}
