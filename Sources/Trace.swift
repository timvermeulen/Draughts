public struct Trace {
    fileprivate let moved: DoubleDictionary<Square, Square>
    public let removed, added: Set<Square>
    
    internal init(moved: DoubleDictionary<Square, Square> = [:], removed: Set<Square> = [], added: Set<Square> = []) {
        self.moved = moved
        self.removed = removed
        self.added = added
    }
    
    public func followed(by other: Trace) -> Trace {
        // All moves starting at a square that is transformed in `self`, but not necessarily in `other`
        let startMoved: [(Square, Square)] = self.moved.flatMap { start, inter in
            guard let end = other.destinationOfPiece(on: inter), start != end else { return nil }
            return (start, end)
        }
        
        // All moves starting at a square that is transformed in `other`, but not necessarily in `self`
        let endMoved: [(Square, Square)] = other.moved.flatMap { inter, end in
            guard let start = self.originOfPiece(on: inter), start != end else { return nil }
            return (start, end)
        }
        
        let moved = DoubleDictionary(startMoved + endMoved)
        let removed = Set(self.removed + other.removed.flatMap(self.originOfPiece))
        let added = Set(other.added + self.added.flatMap(other.destinationOfPiece))
        
        return Trace(moved: moved, removed: removed, added: added)
    }
    
    public func destinationOfPiece(on square: Square) -> Square? {
        guard !self.removed.contains(square) else { return nil }
        return self.moved[key1: square] ?? square
    }
    
    public func originOfPiece(on square: Square) -> Square? {
        guard !self.added.contains(square) else { return nil }
        return self.moved[key2: square] ?? square
    }
    
    public func reversed() -> Trace {
        return Trace(moved: self.moved.reversed(), removed: self.added, added: self.removed)
    }
}

extension Trace: Equatable {
    public static func == (left: Trace, right: Trace) -> Bool {
        return left.moved == right.moved && left.removed == right.removed && left.added == right.added
    }
}

extension Move {
    public var trace: Trace {
        return Trace(
            moved: [self.startSquare: self.endSquare],
            removed: Set(self.captures.map { $0.square })
        )
    }
}

extension Game {
    public var trace: Trace {
        return self.moves
            .map { $0.trace }
            .reduce(Trace()) { $0.followed(by: $1) }
    }
    
    public func trace(from start: PositionIndex, to end: PositionIndex) -> Trace {
        let first = self.gameToPosition(at: start).trace
        let second = self.gameToPosition(at: end).trace
        
        return first.reversed().followed(by: second)
    }
}
