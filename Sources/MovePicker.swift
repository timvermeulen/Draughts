public final class MovePicker {
    public let position: Position
    
    public var candidates: [Move]
    internal var requirements: Bitboard
    
    public var squares: [Square] {
        return Array(requirements.serialized())
    }
    
    public init(_ position: Position) {
        self.position = position
        
        self.candidates = position.legalMoves
        self.requirements = []
    }
}

extension MovePicker {
    public var onlyCandidate: Move? {
        return Optional(self.candidates.first, where: { _ in self.candidates.count == 1 })
    }
    
    private func generateCandidates() {
        let requirements = self.requirements
        self.restore()
        
        for square in requirements.serialized() { self.toggle(square) }
    }
    
    public func restore() {
        self.candidates = position.legalMoves
        self.requirements = .empty
    }
    
    @discardableResult
    public func toggle(_ square: Square) -> Move? {
        guard !self.requirements.contains(square) else {
            self.requirements.remove(square)
            self.generateCandidates()
            return nil
        }
        
        let newCandidates = self.candidates.filter { $0.relevantSquares.contains(square) }
        
        if newCandidates.isEmpty {
            let otherCandidates = self.position.legalMoves.filter { $0.startSquare == square }
            
            if !otherCandidates.isEmpty {
                self.candidates = otherCandidates
                self.requirements = Bitboard(square: square)
            }
        } else {
            self.requirements.insert(square)
            self.candidates = newCandidates
        }
        
        return self.onlyCandidate
    }
    
    public func onlyCandidate(from start: Square, to end: Square) -> Move? {
        func includeMove(_ move: Move) -> Bool {
            return move.startSquare == start && move.endSquare == end
        }
        
        func onlyMove(of moves: [Move]) -> Move? {
            return Optional(moves.first, where: { _ in moves.count == 1 })
        }
        
        return onlyMove(of: self.candidates.filter(includeMove)) ?? onlyMove(of: self.position.legalMoves.filter(includeMove))
    }
}

extension MovePicker: TextOutputStreamable {
    public func write<Target: TextOutputStream>(to target: inout Target) {
        print(
            "position:", self.position,
            "required squares:", self.requirements,
            "candidate moves:", self.candidates.lazy.map { $0.unambiguousNotation }.joined(separator: ", "),
            separator: "\n", terminator: "",
            to: &target
        )
    }
}
