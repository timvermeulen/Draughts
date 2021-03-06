public struct Trace<Element: Hashable> {
    fileprivate let moved: DoubleDictionary<Element, Element>
    public let removed: Set<Element>
    public let added: Set<Element>
    
    internal init(moved: DoubleDictionary<Element, Element> = [:], removed: Set<Element> = [], added: Set<Element> = []) {
        self.moved = moved
        self.removed = removed
        self.added = added
    }
    
    public func followed(by other: Trace) -> Trace {
        // All moves starting at an element that is transformed in `self`, but not necessarily in `other`
        let startMoved: [(Element, Element)] = self.moved.compactMap {
            let (start, inter) = $0
            
            guard let end = other.destination(of: inter), start != end else { return nil }
            return (start, end)
        }
        
        // All moves ending at an element that is transformed in `other`, but not necessarily in `self`
        let endMoved: [(Element, Element)] = other.moved.compactMap {
            let (inter, end) = $0
            
            guard let start = origin(of: inter), start != end else { return nil }
            return (start, end)
        }
        
        let moved = DoubleDictionary(startMoved + endMoved)
        let removed = Set(self.removed + other.removed.compactMap(origin))
        let added = Set(other.added + self.added.compactMap(other.destination))
        
        return Trace(moved: moved, removed: removed, added: added)
    }
    
    public func destination(of element: Element) -> Element? {
        guard !removed.contains(element) else { return nil }
        return moved[key1: element] ?? element
    }
    
    public func origin(of element: Element) -> Element? {
        guard !added.contains(element) else { return nil }
        return moved[key2: element] ?? element
    }
    
    public func reversed() -> Trace {
        return Trace(moved: moved.reversed(), removed: added, added: removed)
    }
}

extension Trace: Equatable {
    public static func == (left: Trace, right: Trace) -> Bool {
        return left.moved == right.moved && left.removed == right.removed && left.added == right.added
    }
}

extension Move {
    public var trace: Trace<Piece> {
        return Trace(
            moved: [startPiece: endPiece],
            removed: Set(captures)
        )
    }
}

extension Game {
    public var trace: Trace<Piece> {
        return moves
            .lazy
            .map { $0.trace }
            .reduce(Trace()) { $0.followed(by: $1) }
    }
    
    public func trace(from start: PositionIndex, to end: PositionIndex) -> Trace<Piece> {
        let first = gameToPosition(at: start).trace
        let second = gameToPosition(at: end).trace
        
        return first.reversed().followed(by: second)
    }
}
