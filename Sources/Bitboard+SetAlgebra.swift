extension Bitboard {
    internal var inverse: Bitboard {
        return Bitboard(~value)
    }
}

extension Bitboard: SetAlgebra {
    public init() {
        self = .empty
    }
    
    public func contains(_ square: Square) -> Bool {
        return value & Bitboard(square: square).value != 0
    }
    
    public func union(_ other: Bitboard) -> Bitboard {
        return Bitboard(value | other.value)
    }
    
    public func intersection(_ other: Bitboard) -> Bitboard {
        return Bitboard(value & other.value)
    }
    
    public func symmetricDifference(_ other: Bitboard) -> Bitboard {
        return Bitboard(value ^ other.value)
    }
    
    public mutating func formUnion(_ other: Bitboard) {
        value |= other.value
    }
    
    public mutating func formIntersection(_ other: Bitboard) {
        value &= other.value
    }
    
    public mutating func formSymmetricDifference(_ other: Bitboard) {
        value ^= other.value
    }
    
    @discardableResult
    public mutating func insert(_ square: Square) -> (inserted: Bool, memberAfterInsert: Square) {
        let inserted = !contains(square)
        value |= Bitboard(square: square).value
        return (inserted, square)
    }
    
    @discardableResult
    public mutating func remove(_ square: Square) -> Square? {
        defer { value &= ~Bitboard(square: square).value }
        return Optional(square, where: contains)
    }
    
    @discardableResult
    public mutating func update(with square: Square) -> Square? {
        return Optional(square, where: { insert($0).inserted })
    }
}
