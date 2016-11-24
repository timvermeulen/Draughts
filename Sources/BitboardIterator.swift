struct BitboardIterator: IteratorProtocol {
    let bitboard: Bitboard
    var index = 0
    
    init(_ bitboard: Bitboard) {
        self.bitboard = bitboard
    }
    
    mutating func next() -> Square? {
        while self.index < 64 {
            defer { self.index += 1 }
            
            guard
                let square = Square(checking: self.index),
                self.bitboard.contains(square)
                else { continue }
            
            return square
        }
        
        return nil
    }
}
