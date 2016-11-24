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
    
    private func generateCandidates() {
        let requirements = self.requirements
        self.restore()
        
        for square in requirements {
            self.toggle(square)
        }
    }
    
    public func restore() {
        self.candidates = position.legalMoves
        self.requirements = .empty
    }
    
    public func toggle(_ square: Square) {
        guard !self.requirements.contains(square) else {
            self.requirements.remove(square)
            self.generateCandidates()
            return
        }
        
        let newCandidates = self.candidates.filter { $0.relevantSquares.contains(square) }
        
        if newCandidates.isEmpty {
            let otherCandidates = self.position.legalMoves.filter { $0.start == square }
            
            if !otherCandidates.isEmpty {
                self.candidates = otherCandidates
                self.requirements = Bitboard(square)
            }
        } else {
            self.requirements.insert(square)
            self.candidates = newCandidates
        }
    }
    
    public func onlyCandidate(from start: Square, to end: Square) -> Move? {
        func includeMove(_ move: Move) -> Bool {
            return move.start == start && move.end == end
        }
        
        func onlyMove(of moves: [Move]) -> Move? {
            guard let move = moves.first, moves.count == 1 else { return nil }
            return move
        }
        
        return onlyMove(of: self.candidates.filter(includeMove)) ?? onlyMove(of: self.position.legalMoves.filter(includeMove))
    }
}
