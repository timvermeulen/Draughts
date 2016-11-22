extension Bitboard {
    var opposite: Bitboard {
        return Bitboard(~self.value)
    }
}

extension Bitboard: SetAlgebra {
    init() {
        self = .empty
    }
    
    internal func contains(_ square: Square) -> Bool {
        return self.value & Bitboard(square).value != 0
    }
    
    func union(_ other: Bitboard) -> Bitboard {
        return Bitboard(self.value | other.value)
    }
    
    func intersection(_ other: Bitboard) -> Bitboard {
        return Bitboard(self.value & other.value)
    }
    
    func symmetricDifference(_ other: Bitboard) -> Bitboard {
        return Bitboard(self.value ^ other.value)
    }
    
    mutating func insert(_ square: Square) -> (inserted: Bool, memberAfterInsert: Square) {
        let inserted = !self.contains(square)
        self.value |= Bitboard(square).value
        return (inserted, square)
    }
    
    mutating func remove(_ square: Square) -> Square? {
        let contained = self.contains(square)
        self.value &= ~Bitboard(square).value
        return contained ? square : nil
    }
    
    mutating func update(with square: Square) -> Square? {
        return self.insert(square).inserted ? square : nil
    }
    
    mutating func formUnion(_ other: Bitboard) {
        self.value |= other.value
    }
    
    mutating func formIntersection(_ other: Bitboard) {
        self.value &= other.value
    }
    
    mutating func formSymmetricDifference(_ other: Bitboard) {
        self.value ^= other.value
    }
}
