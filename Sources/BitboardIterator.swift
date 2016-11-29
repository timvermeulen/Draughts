internal struct BitboardIterator: IteratorProtocol {
    internal let bitboard: Bitboard
    internal var index = 0
    
    internal init(_ bitboard: Bitboard) {
        self.bitboard = bitboard
    }
    
    internal mutating func next() -> Square? {
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
