public final class MovePicker {
    public let position: Position
    
    public var candidates: [Move]
    internal var requirements: Bitboard
    
    public var squares: [Square] {
        return Array(requirements)
    }
    
    public init(_ position: Position) {
        self.position = position
        
        self.candidates = position.legalMoves
        self.requirements = []
    }
}

extension MovePicker {
    public var onlyCandidate: Move? {
        guard
            let move = self.candidates.first,
            self.candidates.count == 1
            else { return nil }
        
        return move
    }
    
    private func restore() {
        self.candidates = position.legalMoves
        self.requirements = .empty
    }
    
    private func generateCandidates() {
        let requirements = self.requirements
        self.restore()
        
        for square in requirements {
            self.toggle(square)
        }
    }
    
    public func toggle(_ square: Square) {
        guard self.requirements.remove(square) == nil else {
            self.generateCandidates()
            return
        }
        
        self.requirements.insert(square)
        self.candidates = self.candidates.filter { $0.relevantSquares.contains(square) }
        
        if self.candidates.isEmpty {
            self.restore()
        }
    }
    
    public func onlyCandidate(from start: Square, to end: Square) -> Move? {
        let filtered = self.candidates.filter { $0.start == start && $0.end == end }
        guard let move = filtered.first, filtered.count == 1 else { return nil }
        return move
    }
}
