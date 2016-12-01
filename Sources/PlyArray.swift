public struct PlyArray<Element> {
    fileprivate var contents: [Element]
    
    public var startPly: Ply
    
    internal init(_ ply: Ply) {
        contents = []
        startPly = ply
    }
}

extension PlyArray: RandomAccessCollection {
    // this should be the default, but leaving it out makes the compiler unhappy
    public typealias Indices = DefaultRandomAccessIndices<PlyArray>
    
    public var startIndex: Ply { return self.startPly }
    public var endIndex: Ply { return self.index(self.startPly, offsetBy: self.contents.count) }
    
    public func index(before ply: Ply) -> Ply {
        return ply.predecessor
    }
    
    public func index(after ply: Ply) -> Ply {
        return ply.successor
    }
    
    public func index(_ ply: Ply, offsetBy offset: Int) -> Ply {
        return Ply(
            player: offset % 2 == 0 ? ply.player : ply.player.opponent,
            number: ply.number + offset
        )
    }
    
    public func distance(from start: Ply, to end: Ply) -> Int {
        return end.number - start.number
    }
    
    public subscript(ply: Ply) -> Element {
        get { return self.contents[ply.number - self.startPly.number] }
        set { self.contents[ply.number - self.startPly.number] = newValue }
    }
    
    public mutating func reserveCapacity(capacity: Int) {
        contents.reserveCapacity(capacity)
    }
}

func yay() {
    let position = Position.start
    print(position)
}

extension PlyArray {
    internal mutating func append(_ element: Element) {
        self.contents.append(element)
    }
}
