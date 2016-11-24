internal struct PlyArray<Element> {
    fileprivate var contents: [Element]
    
    internal var startPly: Ply
    
    internal init(_ ply: Ply) {
        contents = []
        startPly = ply
    }
}

extension PlyArray: RandomAccessCollection {
    internal var startIndex: Ply { return self.startPly }
    internal var endIndex: Ply { return self.index(self.startPly, offsetBy: self.contents.count) }
    
    internal func index(before ply: Ply) -> Ply {
        return ply.predecessor
    }
    
    internal func index(after ply: Ply) -> Ply {
        return ply.successor
    }
    
    internal func index(_ ply: Ply, offsetBy offset: Int) -> Ply {
        return Ply(player: offset % 2 == 0 ? ply.player : ply.player.opponent, number: ply.number + offset)
    }
    
    internal func distance(from start: Ply, to end: Ply) -> Int {
        return end.number - start.number
    }
    
    internal subscript(ply: Ply) -> Element {
        get { return self.contents[ply.number - self.startPly.number] }
        set { self.contents[ply.number - self.startPly.number] = newValue }
    }
    
    internal mutating func reserveCapacity(capacity: Int) {
        contents.reserveCapacity(capacity)
    }
}

extension PlyArray {
    internal mutating func append(_ element: Element) {
        self.contents.append(element)
    }
}
