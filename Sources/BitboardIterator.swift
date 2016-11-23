struct BitboardIterator: IteratorProtocol {
    let bitboard: Bitboard
    var index: Square = 1
    
    init(_ bitboard: Bitboard) {
        self.bitboard = bitboard
    }
    
    mutating func next() -> Square? {
        guard let square = (index.advanced(by: 1) ... 50).first(where: bitboard.contains) else { return nil }
        self.index = square
        return square
    }
}
