public final class MovePicker {
    public let position: Position
    
    public var candidates: [Move]
    internal var requirements: Bitboard
    
    public var squares: [Square] {
        return Array(requirements.serialized())
    }
    
    public init(_ position: Position) {
        self.position = position
        
        candidates = position.legalMoves
        requirements = []
    }
}

extension MovePicker {
    public var onlyCandidate: Move? {
        return Optional(candidates.first, where: { _ in candidates.count == 1 })
    }
    
    private func generateCandidates() {
        let requirements = self.requirements
        restore()
        
        for square in requirements.serialized() { toggle(square) }
    }
    
    public func restore() {
        candidates = position.legalMoves
        requirements = .empty
    }
    
    @discardableResult
    public func toggle(_ square: Square) -> Move? {
        guard !requirements.contains(square) else {
            requirements.remove(square)
            generateCandidates()
            return nil
        }
        
        let newCandidates = candidates.filter { $0.relevantSquares.contains(square) }
        
        if newCandidates.isEmpty {
            let otherCandidates = position.legalMoves.filter { $0.startSquare == square }
            
            if !otherCandidates.isEmpty {
                candidates = otherCandidates
                requirements = Bitboard(square: square)
            }
        } else {
            requirements.insert(square)
            candidates = newCandidates
        }
        
        return onlyCandidate
    }
    
    public func onlyCandidate(from start: Square, to end: Square) -> Move? {
        func includeMove(_ move: Move) -> Bool {
            return move.startSquare == start && move.endSquare == end
        }
        
        func onlyMove(of moves: [Move]) -> Move? {
            return Optional(moves.first, where: { _ in moves.count == 1 })
        }
        
        return onlyMove(of: candidates.filter(includeMove)) ?? onlyMove(of: position.legalMoves.filter(includeMove))
    }
}

extension MovePicker: TextOutputStreamable {
    public func write<Target: TextOutputStream>(to target: inout Target) {
        print(
            "position:", position,
            "required squares:", requirements,
            "candidate moves:", candidates.lazy.map { $0.unambiguousNotation }.joined(separator: ", "),
            separator: "\n", terminator: "",
            to: &target
        )
    }
}
