extension Collection where Self == SubSequence {
    internal mutating func remove(from index: Index) {
        self = self[self.startIndex ..< index]
    }
    
    internal mutating func remove(to index: Index) {
        self = self[index ..< self.endIndex]
    }
}
