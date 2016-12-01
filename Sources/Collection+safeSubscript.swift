extension Collection where Index == Indices.Iterator.Element {
    public subscript(checking index: Index) -> Iterator.Element? {
        guard self.indices.contains(index) else { return nil }
        return self[index]
    }
}

extension MutableCollection where Index == Indices.Iterator.Element {
    public subscript(checking index: Index) -> Iterator.Element? {
        get {
            guard self.indices.contains(index) else { return nil }
            return self[index]
        }
        set {
            if self.indices.contains(index), let value = newValue {
                self[index] = value
            }
        }
    }
}
