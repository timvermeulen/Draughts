public struct Trace {
    fileprivate let moved: DoubleDictionary<Piece, Piece>
    public let removed, added: Set<Piece>
    
    internal init(moved: DoubleDictionary<Piece, Piece> = [:], removed: Set<Piece> = [], added: Set<Piece> = []) {
        self.moved = moved
        self.removed = removed
        self.added = added
    }
    
    public func followed(by other: Trace) -> Trace {
        // All moves starting at a square that is transformed in `self`, but not necessarily in `other`
        let startMoved: [(Piece, Piece)] = self.moved.flatMap { start, inter in
            guard let end = other.destination(of: inter), start != end else { return nil }
            return (start, end)
        }
        
        // All moves starting at a square that is transformed in `other`, but not necessarily in `self`
        let endMoved: [(Piece, Piece)] = other.moved.flatMap { inter, end in
            guard let start = self.origin(of: inter), start != end else { return nil }
            return (start, end)
        }
        
        let moved = DoubleDictionary(startMoved + endMoved)
        let removed = Set(self.removed + other.removed.flatMap(self.origin))
        let added = Set(other.added + self.added.flatMap(other.destination))
        
        return Trace(moved: moved, removed: removed, added: added)
    }
    
    public func destination(of piece: Piece) -> Piece? {
        guard !self.removed.contains(piece) else { return nil }
        return self.moved[key1: piece] ?? piece
    }
    
    public func origin(of piece: Piece) -> Piece? {
        guard !self.added.contains(piece) else { return nil }
        return self.moved[key2: piece] ?? piece
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
            moved: [self.startPiece: self.endPiece],
            removed: Set(self.captures)
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
