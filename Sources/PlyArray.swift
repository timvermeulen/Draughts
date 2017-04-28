public struct PlyArray<Element> {
    fileprivate var contents: ArraySlice<Element>
    
    public var startPly: Ply
    
    internal init(ply: Ply, contents: ArraySlice<Element> = []) {
        self.startPly = ply
        self.contents = contents
    }
}

extension PlyArray {
    fileprivate func sliceIndex(of ply: Ply) -> Int {
        return ply.number - self.startPly.number + self.contents.startIndex
    }
    
    fileprivate func sliceRange(of range: Range<Ply>) -> Range<Int> {
        return self.sliceIndex(of: range.lowerBound) ..< self.sliceIndex(of: range.upperBound)
    }
}

extension PlyArray: RandomAccessCollection {
    // this should be the default, but leaving it out makes the compiler unhappy
    public typealias Indices = DefaultRandomAccessIndices<PlyArray>
    public typealias SubSequence = PlyArray
    
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
        get { return self.contents[self.sliceIndex(of: ply)] }
        set { self.contents[self.sliceIndex(of: ply)] = newValue }
    }
    
    public subscript(range: Range<Ply>) -> PlyArray {
        get { return PlyArray(ply: range.lowerBound, contents: self.contents[self.sliceRange(of: range)]) }
        set { fatalError() }
    }
    
    public mutating func reserveCapacity(capacity: Int) {
        contents.reserveCapacity(capacity)
    }
}

extension PlyArray {
    internal mutating func append(_ element: Element) {
        self.contents.append(element)
    }
    
    internal mutating func append(contentsOf other: PlyArray) {
        assert(self.endIndex == other.startIndex, "ply arrays to be concatenated don't match")
        self.contents.append(contentsOf: other.contents)
    }
}

// TODO: Conditional Conformance
extension PlyArray where Element: Equatable {
    public static func == (left: PlyArray, right: PlyArray) -> Bool {
        return left.contents == right.contents
    }
    
    public static func != (left: PlyArray, right: PlyArray) -> Bool {
        return !(left == right)
    }
}

public func == <Key, Value: Equatable>(left: PlyArray<OrderedDictionary<Key, Value>>, right: PlyArray<OrderedDictionary<Key, Value>>) -> Bool {
    return left.contents.count == right.contents.count && !zip(left.contents, right.contents).contains(where: !=)
}

public func != <Key, Value: Equatable>(left: PlyArray<OrderedDictionary<Key, Value>>, right: PlyArray<OrderedDictionary<Key, Value>>) -> Bool {
    return !(left == right)
}
