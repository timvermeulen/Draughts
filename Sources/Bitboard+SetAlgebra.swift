extension Bitboard {
    internal var inverse: Bitboard {
        return Bitboard(~self.value)
    }
}

extension Bitboard: SetAlgebra {
    public init() {
        self = .empty
    }
    
    public func contains(_ square: Square) -> Bool {
        return self.value & Bitboard(square: square).value != 0
    }
    
    public func union(_ other: Bitboard) -> Bitboard {
        return Bitboard(self.value | other.value)
    }
    
    public func intersection(_ other: Bitboard) -> Bitboard {
        return Bitboard(self.value & other.value)
    }
    
    public func symmetricDifference(_ other: Bitboard) -> Bitboard {
        return Bitboard(self.value ^ other.value)
    }
    
    public mutating func formUnion(_ other: Bitboard) {
        self.value |= other.value
    }
    
    public mutating func formIntersection(_ other: Bitboard) {
        self.value &= other.value
    }
    
    public mutating func formSymmetricDifference(_ other: Bitboard) {
        self.value ^= other.value
    }
    
    @discardableResult
    public mutating func insert(_ square: Square) -> (inserted: Bool, memberAfterInsert: Square) {
        let inserted = !self.contains(square)
        self.value |= Bitboard(square: square).value
        return (inserted, square)
    }
    
    @discardableResult
    public mutating func remove(_ square: Square) -> Square? {
        defer { self.value &= ~Bitboard(square: square).value }
        return Optional(square, where: self.contains)
    }
    
    @discardableResult
    public mutating func update(with square: Square) -> Square? {
        return Optional(square, where: { self.insert($0).inserted })
    }
}
